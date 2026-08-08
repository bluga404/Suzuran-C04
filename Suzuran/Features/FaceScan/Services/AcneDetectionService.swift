import Foundation
import CoreML
import Vision
import CoreGraphics

/// Encapsulates CoreML model loading and YOLO inference for acne detection.
/// Returns `[AcneDetection]` with normalized bounding boxes (top-left origin, no Y-flip).
final class AcneDetectionService {

    // MARK: - Properties

    private let inferenceQueue = DispatchQueue(
        label: "suzuran.ml.acneDetection",
        qos: .userInitiated
    )
    private var visionModel: VNCoreMLModel?
    private var modelLoadError: Error?

    var isModelLoaded: Bool {
        visionModel != nil
    }

    // MARK: - Initialization

    init() {
        setupModel()
    }

    // MARK: - Model Setup

    private func setupModel() {
        let config = MLModelConfiguration()
        // Use CPU + Neural Engine only. The GPU/Metal path triggers
        // `MLIR pass manager failed` on target devices.
        config.computeUnits = .cpuAndNeuralEngine

        do {
            let coreMLModel = try v26_fp16(configuration: config).model
            let vnModel = try VNCoreMLModel(for: coreMLModel)
            self.visionModel = vnModel
            print("[AcneDetectionService] ✅ Model loaded with CPU + Neural Engine")
        } catch {
            self.modelLoadError = error
            print("[AcneDetectionService] ❌ Failed to initialize CoreML model: \(error)")
        }
    }

    // MARK: - Inference

    /// Run inference on a CGImage, returns detections with normalized coordinates.
    /// Uses scaleFill to resize input to 640×640.
    func detect(in cgImage: CGImage) async throws -> [AcneDetection] {
        guard let visionModel = visionModel else {
            let message = modelLoadError?.localizedDescription ?? "Model tidak dimuat."
            throw AppError.unknown(message: "CoreML model gagal dimuat: \(message)")
        }

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async {
                do {
                    let request = VNCoreMLRequest(model: visionModel)
                    request.imageCropAndScaleOption = .scaleFill

                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try handler.perform([request])

                    let detections = Self.parseDetections(from: request.results ?? [])
                    continuation.resume(returning: detections)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Output Parsing

    /// Parses Vision results into `[AcneDetection]`.
    /// Handles both `VNRecognizedObjectObservation` (unlikely) and
    /// `VNCoreMLFeatureValueObservation` (expected end2end path).
    private static func parseDetections(from results: [VNObservation]) -> [AcneDetection] {
        // Path 1: VNRecognizedObjectObservation (standard object detection output)
        if let objectObservations = results as? [VNRecognizedObjectObservation] {
            return objectObservations.compactMap { observation -> AcneDetection? in
                guard let topLabel = observation.labels.first else { return nil }
                let classId = classIdFromLabel(topLabel.identifier)
                guard classId >= 0, classId <= 5 else { return nil }

                return AcneDetection(
                    acneType: AcneType(classId: classId),
                    confidence: Double(topLabel.confidence),
                    normalizedBoundingBox: observation.boundingBox
                )
            }
        }

        // Path 2: VNCoreMLFeatureValueObservation (end2end model output)
        if let featureObservations = results as? [VNCoreMLFeatureValueObservation] {
            return parseEnd2EndOutput(featureObservations)
        }

        return []
    }

    /// Parses end2end YOLO output of shape [1, 300, 6].
    /// Each row: [x1, y1, x2, y2, confidence, class_id] in pixel coords (0–640).
    /// Filters confidence ≥ 0.05, class_id ∈ [0, 5], then applies per-class IoU NMS (threshold 0.35).
    private static func parseEnd2EndOutput(
        _ observations: [VNCoreMLFeatureValueObservation]
    ) -> [AcneDetection] {
        let confidenceThreshold: Float = 0.05
        var raw: [AcneDetection] = []

        for observation in observations {
            guard let multiArray = observation.featureValue.multiArrayValue else { continue }

            let shape = multiArray.shape.map { $0.intValue }

            let numDetections: Int
            let numAttributes: Int

            if shape.count == 3 {
                // [1, numDetections, numAttributes] — end2end format
                numDetections = shape[1]
                numAttributes = shape[2]
            } else if shape.count == 2 {
                // [numDetections, numAttributes]
                numDetections = shape[0]
                numAttributes = shape[1]
            } else {
                continue
            }

            // End2end format requires exactly 6 attributes per detection
            guard numAttributes == 6 else { continue }

            let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

            for d in 0..<numDetections {
                let baseIdx = d * numAttributes
                let x1 = pointer[baseIdx + 0]
                let y1 = pointer[baseIdx + 1]
                let x2 = pointer[baseIdx + 2]
                let y2 = pointer[baseIdx + 3]
                let conf = pointer[baseIdx + 4]
                let classId = Int(pointer[baseIdx + 5])

                guard conf >= confidenceThreshold else { continue }
                guard classId >= 0, classId <= 5 else { continue }

                let midpoint = CoordinateNormalizer.normalize(
                    x1: CGFloat(x1), y1: CGFloat(y1),
                    x2: CGFloat(x2), y2: CGFloat(y2)
                )
                let modelSize = CoordinateNormalizer.modelInputSize
                let normWidth  = CGFloat(x2 - x1) / modelSize
                let normHeight = CGFloat(y2 - y1) / modelSize
                let normX = midpoint.x - normWidth  / 2.0
                let normY = midpoint.y - normHeight / 2.0

                let normalizedBBox = CGRect(
                    x: CoordinateNormalizer.clamp(normX),
                    y: CoordinateNormalizer.clamp(normY),
                    width:  CoordinateNormalizer.clamp(normWidth),
                    height: CoordinateNormalizer.clamp(normHeight)
                )
                raw.append(AcneDetection(
                    acneType: AcneType(classId: classId),
                    confidence: Double(conf),
                    normalizedBoundingBox: normalizedBBox
                ))
            }
        }

        // Apply per-class NMS to remove stacked/overlapping boxes.
        return nms(raw, iouThreshold: 0.35)
    }

    // MARK: - NMS

    /// Per-class, confidence-sorted IoU Non-Maximum Suppression.
    /// - Parameters:
    ///   - detections: Raw detections (may contain heavy overlap).
    ///   - iouThreshold: Boxes with IoU ≥ this value relative to a kept box are suppressed. 0.35 is aggressive.
    /// - Returns: Deduplicated detections.
    private static func nms(_ detections: [AcneDetection], iouThreshold: Double) -> [AcneDetection] {
        // Group by class, then run greedy NMS inside each group.
        let byClass = Dictionary(grouping: detections, by: \.acneType)
        var kept: [AcneDetection] = []

        for (_, group) in byClass {
            // Sort descending by confidence
            var sorted = group.sorted { $0.confidence > $1.confidence }
            while !sorted.isEmpty {
                let best = sorted.removeFirst()
                kept.append(best)
                // Suppress all remaining boxes that overlap too much with `best`
                sorted = sorted.filter { iou(best.normalizedBoundingBox, $0.normalizedBoundingBox) < iouThreshold }
            }
        }
        return kept
    }

    /// Intersection-over-Union for two CGRects in normalised 0–1 space.
    private static func iou(_ a: CGRect, _ b: CGRect) -> Double {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }
        let intersectionArea = Double(intersection.width * intersection.height)
        let unionArea = Double(a.width * a.height) + Double(b.width * b.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }

    // MARK: - Testable Parsing

    /// Parses raw float data representing YOLO end2end output of shape [numDetections, 6].
    /// Each row: [x1, y1, x2, y2, confidence, class_id].
    /// Filters confidence ≥ 0.05, class_id ∈ [0, 5].
    /// Returns AcneDetection array with normalized bounding boxes.
    ///
    /// This method is `internal` (not private) to allow property-based testing via @testable import.
    static func parseRawDetections(
        from data: [Float],
        numDetections: Int,
        confidenceThreshold: Float = 0.05
    ) -> [AcneDetection] {
        let numAttributes = 6
        guard data.count == numDetections * numAttributes else { return [] }

        var detections: [AcneDetection] = []

        for d in 0..<numDetections {
            let baseIdx = d * numAttributes
            let x1 = data[baseIdx + 0]
            let y1 = data[baseIdx + 1]
            let x2 = data[baseIdx + 2]
            let y2 = data[baseIdx + 3]
            let conf = data[baseIdx + 4]
            let classId = Int(data[baseIdx + 5])

            guard conf >= confidenceThreshold else { continue }
            guard classId >= 0, classId <= 5 else { continue }

            let midpoint = CoordinateNormalizer.normalize(
                x1: CGFloat(x1),
                y1: CGFloat(y1),
                x2: CGFloat(x2),
                y2: CGFloat(y2)
            )

            let modelSize = CoordinateNormalizer.modelInputSize
            let normWidth = CGFloat(x2 - x1) / modelSize
            let normHeight = CGFloat(y2 - y1) / modelSize
            let normX = midpoint.x - normWidth / 2.0
            let normY = midpoint.y - normHeight / 2.0

            let normalizedBBox = CGRect(
                x: CoordinateNormalizer.clamp(normX),
                y: CoordinateNormalizer.clamp(normY),
                width: CoordinateNormalizer.clamp(normWidth),
                height: CoordinateNormalizer.clamp(normHeight)
            )

            detections.append(AcneDetection(
                acneType: AcneType(classId: classId),
                confidence: Double(conf),
                normalizedBoundingBox: normalizedBBox
            ))
        }

        return detections
    }

    // MARK: - Helpers

    /// Maps a label string to class_id for the VNRecognizedObjectObservation path.
    private static func classIdFromLabel(_ label: String) -> Int {
        switch label.lowercased() {
        case "blackhead": return 0
        case "cyst": return 1
        case "nodule": return 2
        case "papule": return 3
        case "pustule": return 4
        case "whitehead": return 5
        default: return -1
        }
    }
}
