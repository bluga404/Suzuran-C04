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
            let coreMLModel = try best_model_coreml(configuration: config).model
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

    /// Parses VNCoreMLFeatureValueObservation from a YOLO model that doesn't automatically
    /// produce VNRecognizedObjectObservation. Extracts bounding boxes from the raw MLMultiArray.
    private static func parseYOLOFeatureObservations(_ observations: [VNCoreMLFeatureValueObservation]) -> [AcneDetectionResult] {
        // YOLO class labels matching the trained model
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]
        let confidenceThreshold: Float = 0.25

        var results: [AcneDetectionResult] = []

        for observation in observations {
            guard let multiArray = observation.featureValue.multiArrayValue else { continue }

            let shape = multiArray.shape.map { $0.intValue }
            print("[AcneDetectionService] 📐 MultiArray shape: \(shape)")

            // YOLO output shape is typically [1, numAttributes, numDetections]
            // where numAttributes = 4 (bbox) + numClasses
            guard shape.count >= 2 else { continue }

            let numAttributes: Int
            let numDetections: Int

            if shape.count == 3 {
                // [1, numAttributes, numDetections]
                numAttributes = shape[1]
                numDetections = shape[2]
            } else {
                // [numAttributes, numDetections]
                numAttributes = shape[0]
                numDetections = shape[1]
            }

            let numClasses = numAttributes - 4 // 4 bbox values (cx, cy, w, h)
            guard numClasses > 0 && numClasses <= classLabels.count else {
                print("[AcneDetectionService] ⚠️ Unexpected numClasses: \(numClasses)")
                continue
            }

            let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

            for d in 0..<numDetections {
                // Find the best class
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

                // Extract bounding box (center x, center y, width, height) — all normalized 0–1
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

        // A raw YOLO head can emit thousands of candidates. Running NMS against every
        // candidate is quadratic and made a five-zone scan appear to hang. Keep only
        // the strongest candidates; it is more than enough for acne detections.
        let maximumCandidatesForNMS = 300
        let maximumDetections = 100
        let sorted = results.sorted { $0.confidence > $1.confidence }
        let candidates = sorted.prefix(maximumCandidatesForNMS)
        var kept: [AcneDetectionResult] = []
        kept.reserveCapacity(min(candidates.count, maximumDetections))
        let iouThreshold: CGFloat = 0.45

        for candidate in candidates {
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
