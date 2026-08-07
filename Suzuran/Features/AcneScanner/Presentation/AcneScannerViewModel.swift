import Foundation
import UIKit
import Combine

@MainActor
final class AcneScannerViewModel: ObservableObject {

    // MARK: - State

    enum ScanState: Equatable {
        case idle
        case analyzing
        case result
        case failed(String)
    }

    @Published private(set) var state: ScanState = .idle
    @Published private(set) var displayImage: UIImage?
    @Published private(set) var detections: [AcneDetection] = []
    @Published private(set) var scoreResult: SkinHealthResult?

    private var selectedImageData: Data?

    // MARK: - Actions

    func loadImage(data: Data) {
        detections = []
        scoreResult = nil
        state = .idle
        selectedImageData = data
        displayImage = UIImage(data: data)
    }

    func analyze() {
        guard let displayImage,
              let cgImage = displayImage.cgImage else {
            state = .failed("Could not load image")
            return
        }

        state = .analyzing

        let orientation = CGImagePropertyOrientation(displayImage.imageOrientation)

        Task {
            do {
                let (foundDetections, score) = try await Task.detached(priority: .userInitiated) {
                    let dets = try AcneDetectionService.detect(in: cgImage, orientation: orientation)
                    let score = SkinHealthScore.calculate(from: dets)
                    return (dets, score)
                }.value

                detections = foundDetections
                scoreResult = score
                state = .result
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func reset() {
        selectedImageData = nil
        displayImage = nil
        detections = []
        scoreResult = nil
        state = .idle
    }
}

// MARK: - UIImage.Orientation Helper

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
