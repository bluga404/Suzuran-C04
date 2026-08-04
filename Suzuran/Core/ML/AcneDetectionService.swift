import CoreML
import Vision
import Foundation

/// Runs YOLO object detection on face images to detect acne
enum AcneDetectionService {

    // HARDCODE active model name here (corresponds to .mlpackage name added to target)
    nonisolated static let activeModelName = "yolov26_v2"
    // static let activeModelName = "yolov26_v2"

    /// Detects acne in a CGImage using the active CoreML model.
    ///
    /// - Parameters:
    ///   - cgImage: The image to analyze
    ///   - confidenceThreshold: Minimum confidence to include a detection (default: 0.25)
    /// - Returns: Array of detected acne lesions
    nonisolated static func detect(
        in cgImage: CGImage,
        confidenceThreshold: Float = 0.25
    ) throws -> [AcneDetection] {
        let modelURL = try findModelURL(for: activeModelName)

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        let mlModel = try MLModel(contentsOf: modelURL, configuration: configuration)
        let visionModel = try VNCoreMLModel(for: mlModel)

        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        var detections: [AcneDetection] = []

        // Parse results (handles standard Vision format or raw YOLO MultiArray format)
        if let observations = request.results as? [VNRecognizedObjectObservation], !observations.isEmpty {
            for observation in observations {
                guard let topLabel = observation.labels.first,
                      topLabel.confidence >= confidenceThreshold,
                      let acneType = AcneType.from(label: topLabel.identifier) else {
                    continue
                }

                detections.append(
                    AcneDetection(
                        acneType: acneType,
                        confidence: topLabel.confidence,
                        boundingBox: observation.boundingBox
                    )
                )
            }
        } else if let features = request.results as? [VNCoreMLFeatureValueObservation],
                  let firstFeature = features.first,
                  let multiArray = firstFeature.featureValue.multiArrayValue {
            
            let shape = multiArray.shape.map { $0.intValue }
            if shape.count >= 2 {
                let numDetections = shape[shape.count - 2]
                
                for i in 0..<numDetections {
                    let makeIndex: (Int) -> [NSNumber] = { featIndex in
                        shape.count == 3 ? [0, i, featIndex] as [NSNumber] : [i, featIndex] as [NSNumber]
                    }
                    
                    let x = multiArray[makeIndex(0)].floatValue
                    let y = multiArray[makeIndex(1)].floatValue
                    let w = multiArray[makeIndex(2)].floatValue
                    let h = multiArray[makeIndex(3)].floatValue
                    let confidence = multiArray[makeIndex(4)].floatValue
                    let classId = multiArray[makeIndex(5)].intValue
                    
                    guard confidence >= confidenceThreshold else { continue }
                    
                    guard let acneType = AcneType.from(label: String(classId)) else {
                        continue
                    }
                    
                    // Determine coordinate scale (0..1 normalized or 0..640 pixel coordinates)
                    let scale: Float = (x > 1.0 || y > 1.0 || w > 1.0 || h > 1.0) ? 640.0 : 1.0
                    
                    let val0 = x / scale
                    let val1 = y / scale
                    let val2 = w / scale
                    let val3 = h / scale
                    
                    let cx: Float
                    let cy: Float
                    let boxW: Float
                    let boxH: Float
                    
                    if val2 > val0 {
                        // Likely [x1, y1, x2, y2]
                        boxW = val2 - val0
                        boxH = val3 - val1
                        cx = val0 + boxW / 2.0
                        cy = val1 + boxH / 2.0
                    } else {
                        // Likely [cx, cy, w, h]
                        cx = val0
                        cy = val1
                        boxW = val2
                        boxH = val3
                    }
                    
                    // Convert center-x, center-y, width, height to Vision rect (origin bottom-left, y goes up)
                    let rectX = cx - boxW / 2.0
                    let rectY = 1.0 - (cy + boxH / 2.0)
                    
                    let boundingBox = CGRect(
                        x: CGFloat(max(0.0, min(1.0, rectX))),
                        y: CGFloat(max(0.0, min(1.0, rectY))),
                        width: CGFloat(max(0.0, min(1.0, boxW))),
                        height: CGFloat(max(0.0, min(1.0, boxH)))
                    )
                    
                    detections.append(
                        AcneDetection(
                            acneType: acneType,
                            confidence: confidence,
                            boundingBox: boundingBox
                        )
                    )
                }
            }
        }

        return detections
    }

    private nonisolated static func findModelURL(for name: String) throws -> URL {
        // Direct exact match
        if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            return url
        }
        // Fallback replacement (hyphen vs underscore)
        let alternativeName = name.replacingOccurrences(of: "_", with: "-")
        if let url = Bundle.main.url(forResource: alternativeName, withExtension: "mlmodelc") {
            return url
        }
        
        let normalizedAlternativeName = name.replacingOccurrences(of: "-", with: "_")
        if let url = Bundle.main.url(forResource: normalizedAlternativeName, withExtension: "mlmodelc") {
            return url
        }

        throw AppError.unknown(message: "ML model '\(name)' not found in app bundle. Make sure it is added to the Xcode target.")
    }
}
