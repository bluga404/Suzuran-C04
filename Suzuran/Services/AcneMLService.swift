import Foundation
import CoreML
import Vision
import UIKit

class AcneMLService {
    
    // Normalizes image orientation to .up so Vision gets the correct coordinates
    static func normalizedOrientation(for image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    func detectAcne(in image: UIImage, completion: @escaping ([String: Int], Error?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([:], NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid CGImage"]))
            return
        }
        
        do {
            // Setup the model
            let modelConfig = MLModelConfiguration()
            let coreMLModel = try Acne_1(configuration: modelConfig) // Ensure Acne_1 matches the auto-generated class
            let visionModel = try VNCoreMLModel(for: coreMLModel.model)
            
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    completion([:], error)
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    completion([:], nil)
                    return
                }
                
                // Count occurrences of each label
                var counts: [String: Int] = [:]
                for observation in results {
                    // Get the top classification label
                    guard let topLabel = observation.labels.first?.identifier else { continue }
                    counts[topLabel, default: 0] += 1
                }
                
                completion(counts, nil)
            }
            
            // Adjust threshold if needed
            request.imageCropAndScaleOption = .scaleFit
            
            let orientation = Self.normalizedOrientation(for: image)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            
            // Run in background to avoid blocking main thread
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    completion([:], error)
                }
            }
        } catch {
            completion([:], error)
        }
    }
}
