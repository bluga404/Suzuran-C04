import Foundation
import UIKit
import CoreML
import Vision

nonisolated final class PredictionService: @unchecked Sendable {
    private static let classNames = ["comedo", "nodule/cystic", "papule", "pustule"]
    private let confidenceThreshold = 0.05

    private let model: MLModel?
    private let visionModel: VNCoreMLModel?
    private let request: VNCoreMLRequest?

    init() {
        guard
            let url = Bundle.main.url(forResource: "best", withExtension: "mlmodelc"),
            let model = try? MLModel(contentsOf: url),
            let visionModel = try? VNCoreMLModel(for: model)
        else {
            self.model = nil
            self.visionModel = nil
            self.request = nil
            return
        }

        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill

        self.model = model
        self.visionModel = visionModel
        self.request = request
    }

    nonisolated func predict(_ image: UIImage) throws -> [AcneDetection] {
        guard let request else { throw PredictionServiceError.modelNotLoaded }
        guard let cgImage = image.cgImage else { throw PredictionServiceError.invalidImage }

        let orientation = Self.cgOrientation(from: image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([request])

        guard
            let observation = request.results?
                .compactMap({ $0 as? VNCoreMLFeatureValueObservation })
                .first(where: { $0.featureValue.type == .multiArray }),
            let multiArray = observation.featureValue.multiArrayValue
        else { throw PredictionServiceError.invalidOutput }

        #if DEBUG
        print("[PredictionService] number of result observations: \(request.results?.count ?? 0)")
        Self.debugPrintMultiArray(multiArray)
        #endif

        return Self.parseDetections(multiArray, threshold: confidenceThreshold)
    }

    nonisolated func topPrediction(from detections: [AcneDetection], image: UIImage) -> PredictionResult? {
        guard let top = detections.first else { return nil }
        return PredictionResult(acneType: top.label, confidence: top.confidence, image: image)
    }

    nonisolated static func parseDetections(_ array: MLMultiArray, threshold: Double) -> [AcneDetection] {
        guard array.shape.count == 3, array.shape[1].intValue > 0 else { return [] }

        let rowCount = array.shape[1].intValue
        let rowStride = array.strides[1].intValue
        let colStride = array.strides[2].intValue

        let pointer = array.dataPointer.assumingMemoryBound(to: Float32.self)

        var detections: [AcneDetection] = []
        for row in 0..<rowCount {
            let base = row * rowStride

            let confidence = Double(pointer[base + 4 * colStride])
            guard confidence >= threshold else { continue }

            let x1 = pointer[base]
            let y1 = pointer[base + colStride]
            let x2 = pointer[base + 2 * colStride]
            let y2 = pointer[base + 3 * colStride]
            let classIndex = Int(pointer[base + 5 * colStride])

            let label = (classIndex >= 0 && classIndex < classNames.count) ? classNames[classIndex] : "Unknown"
            let box = CGRect(
                x: CGFloat(x1),
                y: CGFloat(y1),
                width: CGFloat(x2 - x1),
                height: CGFloat(y2 - y1)
            )

            detections.append(
                AcneDetection(classIndex: classIndex, label: label, confidence: confidence, box: box)
            )
        }

        return detections.sorted { $0.confidence > $1.confidence }
    }

    nonisolated static func cgOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        case .left: return .left
        @unknown default: return .up
        }
    }

    nonisolated static func debugPrintMultiArray(_ array: MLMultiArray) {        guard array.shape.count == 3, array.shape[1].intValue > 0 else {
            print("[PredictionService] unexpected output shape: \(array.shape)")
            return
        }

        let rowCount = array.shape[1].intValue
        let colCount = array.shape[2].intValue
        let rowStride = array.strides[1].intValue
        let colStride = array.strides[2].intValue
        let pointer = array.dataPointer.assumingMemoryBound(to: Float32.self)

        print("[PredictionService] shape=\(array.shape) strides=\(array.strides)")

        var maxConfidence: Float = 0
        var rowsAboveThreshold = 0
        for row in 0..<rowCount {
            let base = row * rowStride
            let confidence = pointer[base + 4 * colStride]
            if confidence > maxConfidence { maxConfidence = confidence }
            if confidence > 0.005 { rowsAboveThreshold += 1 }
        }
        print("[PredictionService] max confidence=\(maxConfidence) rows with confidence>0.005: \(rowsAboveThreshold)")

        for row in 0..<min(rowCount, 10) {
            let base = row * rowStride
            let values = (0..<colCount).map { pointer[base + $0 * colStride] }
            print("[PredictionService] row \(row): \(values)")
        }
    }
}

enum PredictionServiceError: LocalizedError {
    case modelNotLoaded
    case invalidImage
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "The machine learning model could not be loaded."
        case .invalidImage:
            return "The image could not be read."
        case .invalidOutput:
            return "The model produced an unexpected output."
        }
    }
}
