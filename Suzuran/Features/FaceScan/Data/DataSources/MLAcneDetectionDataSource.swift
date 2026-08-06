import Foundation
import UIKit

protocol MLAcneDetectionDataSourceProtocol {
    func detect(in imageData: Data) async throws -> [AcneDetectionResult]
}

final class MLAcneDetectionDataSource: MLAcneDetectionDataSourceProtocol {
    private let detectionService: AcneDetectionService

    init(detectionService: AcneDetectionService = AcneDetectionService()) {
        self.detectionService = detectionService
    }

    func detect(in imageData: Data) async throws -> [AcneDetectionResult] {
        guard let uiImage = UIImage(data: imageData) else {
            print("[MLAcneDetectionDataSource] ❌ Cannot create UIImage from data (\(imageData.count) bytes)")
            throw AppError.decoding
        }

        // Resize image to 640x640 for YOLO model input
        let targetSize = CGSize(width: 640, height: 640)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let cgImage = resizedImage.cgImage else {
            print("[MLAcneDetectionDataSource] ❌ Cannot get cgImage from resized image")
            throw AppError.decoding
        }

        print("[MLAcneDetectionDataSource] 📸 Running detection on \(targetSize.width)x\(targetSize.height) image")
        return try await detectionService.detect(in: cgImage)
    }
}
