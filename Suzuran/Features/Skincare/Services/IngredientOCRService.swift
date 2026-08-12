import UIKit
import Vision

/// Vision-backed OCR service that extracts raw text from an ingredient label image.
///
/// Wraps low-level Vision failures into the module's unified ``SkincareError/ocrFailed``
/// so the UI can bind a localized (Bahasa Indonesia) message directly (Req 19.1, 19.2).
/// Technical details are logged via ``AppLogger`` with the `[Skincare]` tag.
final class IngredientOCRService {

    private let logger: AppLogging

    init(logger: AppLogging = AppLogger()) {
        self.logger = logger
    }

    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            logger.error("[Skincare] OCR: UIImage has no backing CGImage")
            throw SkincareError.ocrFailed
        }

        do {
            return try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let text = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")

                    continuation.resume(returning: text)
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en-US"]

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try handler.perform([request])
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            logger.error("[Skincare] OCR: Vision recognition failed: \(error)")
            throw SkincareError.ocrFailed
        }
    }
}
