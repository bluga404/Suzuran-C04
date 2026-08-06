import Foundation
import CoreML
import Vision
import CoreGraphics
import UIKit

final class AcneDetectionService {
    /// Core ML/Vision work must not occupy the main actor while a scan result is shown.
    private let inferenceQueue = DispatchQueue(
        label: "suzuran.ml.acneDetection",
        qos: .userInitiated
    )
    private var visionModel: VNCoreMLModel?
    private var modelLoadError: Error?

    init() {
        setupModel()
    }

    var isModelLoaded: Bool {
        visionModel != nil
    }

    private func setupModel() {
        let config = MLModelConfiguration()
        // `.all` allows Core ML to select the GPU. On the target device the
        // Metal/MPSGraph compiler aborts during this model's inference with
        // `MLIR pass manager failed`, which cannot be handled by Swift `catch`.
        // Keep the GPU out of this model's execution path while retaining the
        // Neural Engine when the device supports it.
        config.computeUnits = .cpuAndNeuralEngine

        do {
            let coreMLModel = try best(configuration: config).model
            let vnModel = try VNCoreMLModel(for: coreMLModel)
            self.visionModel = vnModel
            print("[AcneDetectionService] ✅ Model loaded with CPU + Neural Engine")
        } catch {
            self.modelLoadError = error
            print("[AcneDetectionService] ❌ Failed to initialize CoreML model: \(error)")
        }
    }

    func detect(in cgImage: CGImage) async throws -> [AcneDetectionResult] {
        guard let visionModel = visionModel else {
            let message = modelLoadError?.localizedDescription ?? "Model tidak dimuat."
            throw AppError.unknown(message: "CoreML model gagal dimuat: \(message)")
        }

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async {
                do {
                    // `perform` returns only after Vision has completed or failed every
                    // request. Reading `results` here avoids an extra callback/continuation
                    // hand-off that could otherwise leave the loading state unresolved.
                    let request = VNCoreMLRequest(model: visionModel)
                    request.imageCropAndScaleOption = .scaleFill
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                    print("[AcneDetectionService] ▶️ Starting Vision request")
                    try handler.perform([request])
                    let detections = Self.detections(from: request.results ?? [])
                    print("[AcneDetectionService] ✅ Vision request completed with \(detections.count) detections")
                    continuation.resume(returning: detections)
                } catch {
                    print("[AcneDetectionService] ❌ Vision request failed: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Parse Raw YOLO Output

    private static func detections(from results: [VNObservation]) -> [AcneDetectionResult] {
        print("[AcneDetectionService] 📊 Got \(results.count) results, types: \(results.map { type(of: $0) })")

        if let objectObservations = results as? [VNRecognizedObjectObservation] {
            let detections = objectObservations.compactMap { observation -> AcneDetectionResult? in
                guard let topLabel = observation.labels.first else { return nil }
                return AcneDetectionResult(
                    label: topLabel.identifier,
                    confidence: topLabel.confidence,
                    boundingBox: observation.boundingBox
                )
            }
            print("[AcneDetectionService] ✅ Detected \(detections.count) objects via VNRecognizedObjectObservation")
            return detections
        }

        if let featureObservations = results as? [VNCoreMLFeatureValueObservation] {
            print("[AcneDetectionService] 📊 Got \(featureObservations.count) feature observations")
            return parseYOLOFeatureObservations(featureObservations)
        }

        print("[AcneDetectionService] ⚠️ Unknown result type, returning empty")
        return []
    }

    /// Parses VNCoreMLFeatureValueObservation from a YOLO end2end model.
    ///
    /// The new model (best.mlpackage, YOLO26s end2end) outputs shape `[1, 300, 6]`:
    ///   - Dimension 0: batch (always 1)
    ///   - Dimension 1: number of candidate detections (300)
    ///   - Dimension 2: 6 values per detection = [cx, cy, w, h, confidence, class_id]
    ///
    /// All bbox values are in pixel coordinates (0–640) and must be normalized to 0–1.
    private static func parseYOLOFeatureObservations(_ observations: [VNCoreMLFeatureValueObservation]) -> [AcneDetectionResult] {
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]
        let confidenceThreshold: Float = 0.25
        let imageSize: Float = 640.0  // Model input size

        var results: [AcneDetectionResult] = []

        for observation in observations {
            guard let multiArray = observation.featureValue.multiArrayValue else { continue }

            let shape = multiArray.shape.map { $0.intValue }
            print("[AcneDetectionService] 📐 MultiArray shape: \(shape)")

            let numDetections: Int
            let numAttributes: Int

            if shape.count == 3 {
                // [1, numDetections, numAttributes]  — end2end format
                numDetections = shape[1]
                numAttributes = shape[2]
            } else if shape.count == 2 {
                // [numDetections, numAttributes]
                numDetections = shape[0]
                numAttributes = shape[1]
            } else {
                print("[AcneDetectionService] ⚠️ Unexpected shape dimensions: \(shape.count)")
                continue
            }

            // End2end YOLO format: numAttributes == 6 → [cx, cy, w, h, conf, class_id]
            // Classic YOLO format: numAttributes == 4 + numClasses → [cx, cy, w, h, class_scores...]
            let isEnd2End = (numAttributes == 6)
            print("[AcneDetectionService] 📐 numDetections=\(numDetections), numAttributes=\(numAttributes), end2end=\(isEnd2End)")

            let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

            if isEnd2End {
                // ── End2End format: [batch?, numDetections, 6] ──
                // Layout in memory (row-major): detection[d] starts at d * 6
                for d in 0..<numDetections {
                    let baseIdx = d * numAttributes
                    let cx   = pointer[baseIdx + 0]
                    let cy   = pointer[baseIdx + 1]
                    let w    = pointer[baseIdx + 2]
                    let h    = pointer[baseIdx + 3]
                    let conf = pointer[baseIdx + 4]
                    let classId = Int(pointer[baseIdx + 5])

                    guard conf >= confidenceThreshold else { continue }
                    guard classId >= 0 && classId < classLabels.count else { continue }

                    // Normalize pixel coords to 0–1
                    let rect = CGRect(
                        x: CGFloat((cx - w / 2) / imageSize),
                        y: CGFloat((cy - h / 2) / imageSize),
                        width: CGFloat(w / imageSize),
                        height: CGFloat(h / imageSize)
                    )

                    results.append(AcneDetectionResult(
                        label: classLabels[classId],
                        confidence: conf,
                        boundingBox: rect
                    ))
                }
            } else {
                // ── Classic YOLO format: [batch?, numAttributes, numDetections] ──
                // numAttributes = 4 + numClasses, data laid out as attribute-major
                let numClasses = numAttributes - 4
                guard numClasses > 0 && numClasses <= classLabels.count else {
                    print("[AcneDetectionService] ⚠️ Unexpected numClasses: \(numClasses)")
                    continue
                }

                for d in 0..<numDetections {
                    var bestClassIdx = 0
                    var bestScore: Float = 0

                    for c in 0..<numClasses {
                        let score = pointer[(4 + c) * numDetections + d]
                        if score > bestScore {
                            bestScore = score
                            bestClassIdx = c
                        }
                    }

                    guard bestScore >= confidenceThreshold else { continue }

                    let cx = CGFloat(pointer[0 * numDetections + d])
                    let cy = CGFloat(pointer[1 * numDetections + d])
                    let w  = CGFloat(pointer[2 * numDetections + d])
                    let h  = CGFloat(pointer[3 * numDetections + d])

                    let rect = CGRect(
                        x: cx - w / 2,
                        y: cy - h / 2,
                        width: w,
                        height: h
                    )

                    let label = bestClassIdx < classLabels.count ? classLabels[bestClassIdx] : "unknown"
                    results.append(AcneDetectionResult(
                        label: label,
                        confidence: bestScore,
                        boundingBox: rect
                    ))
                }
            }
        }

        // NMS: keep strongest non-overlapping detections
        let maximumDetections = 100
        let sorted = results.sorted { $0.confidence > $1.confidence }
        var kept: [AcneDetectionResult] = []
        kept.reserveCapacity(min(sorted.count, maximumDetections))
        let iouThreshold: CGFloat = 0.45

        for candidate in sorted {
            let dominated = kept.contains { existing in
                Self.iou(existing.boundingBox, candidate.boundingBox) > iouThreshold
            }
            if !dominated {
                kept.append(candidate)
                if kept.count == maximumDetections {
                    break
                }
            }
        }

        print("[AcneDetectionService] 📊 After NMS: \(kept.count) detections from \(results.count) candidates")
        return kept
    }

    /// Intersection over Union for simple NMS
    private static func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }
}
