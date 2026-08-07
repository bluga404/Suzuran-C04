import CoreML
import Vision
import Foundation

/// Runs YOLO object detection on face images to detect acne.
enum AcneDetectionService {

    /// Active CoreML model name (bundle resource without extension)
    nonisolated static let activeModelName = "yolov11s_62_6"

    /// Cached VNCoreMLModel instance loaded safely once on thread startup.
    nonisolated(unsafe) private static let cachedVisionModel: VNCoreMLModel? = {
        print("[AcneDetectionService] Loading model: \(activeModelName)...")
        do {
            let modelURL = try findModelURL(for: activeModelName)
            print("[AcneDetectionService] Model URL resolved: \(modelURL.path)")
            
            let configuration = MLModelConfiguration()
            // Force CPU execution to prevent Metal Performance Shaders (MPSGraph) assertion crashes on simulator/devices
            configuration.computeUnits = .cpuOnly
            
            let mlModel = try MLModel(contentsOf: modelURL, configuration: configuration)
            let visionModel = try VNCoreMLModel(for: mlModel)
            print("[AcneDetectionService] VNCoreMLModel initialized successfully.")
            return visionModel
        } catch {
            print("[AcneDetectionService] Failed to initialize model '\(activeModelName)': \(error)")
            return nil
        }
    }()

    /// Detects acne in a CGImage using the active CoreML model.
    ///
    /// - Parameters:
    ///   - cgImage: The image to analyze
    ///   - orientation: CGImagePropertyOrientation to correctly handle EXIF camera orientations
    ///   - confidenceThreshold: Minimum confidence to include a detection (default: 0.25, matches PyTorch .pt default)
    /// - Returns: Array of detected acne lesions
    nonisolated static func detect(
        in cgImage: CGImage,
        orientation: CGImagePropertyOrientation = .up,
        confidenceThreshold: Float = 0.25
    ) throws -> [AcneDetection] {
        print("[AcneDetectionService] Starting detection on image (\(cgImage.width)x\(cgImage.height))...")
        
        guard let visionModel = cachedVisionModel else {
            print("[AcneDetectionService] Cached model is nil.")
            throw AppError.unknown(message: "Failed to initialize ML model '\(activeModelName)'. Make sure it is added to the app target.")
        }

        var detections: [AcneDetection] = []
        var executionError: Error?

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error = error {
                print("[AcneDetectionService] VNCoreMLRequest error: \(error)")
                executionError = error
                return
            }

            guard let results = request.results else {
                print("[AcneDetectionService] Request completed with empty results.")
                return
            }

            // 1. Vision Recognized Object Observations (NMS = True pipeline models)
            if let observations = results as? [VNRecognizedObjectObservation], !observations.isEmpty {
                print("[AcneDetectionService] Parsing \(observations.count) VNRecognizedObjectObservations...")
                for (index, observation) in observations.enumerated() {
                    guard let topLabel = observation.labels.first else { continue }
                    
                    guard topLabel.confidence >= confidenceThreshold,
                          let acneType = AcneType.from(label: topLabel.identifier) else {
                        continue
                    }

                    print("[AcneDetectionService] Detection [\(index)]: \(acneType.displayName) (\(Int(topLabel.confidence * 100))%)")

                    detections.append(
                        AcneDetection(
                            acneType: acneType,
                            confidence: topLabel.confidence,
                            boundingBox: observation.boundingBox
                        )
                    )
                }
            }
            // 2. Raw MLMultiArray Feature Observations (Fallback for raw multiarray outputs)
            else if let features = results as? [VNCoreMLFeatureValueObservation] {
                print("[AcneDetectionService] Parsing \(features.count) raw MLMultiArray features...")
                
                // Check for separate NMS outputs (confidence & coordinates)
                if let confidenceFeature = features.first(where: { $0.featureName == "confidence" }),
                   let coordinatesFeature = features.first(where: { $0.featureName == "coordinates" }),
                   let confidenceMultiArray = confidenceFeature.featureValue.multiArrayValue,
                   let coordinatesMultiArray = coordinatesFeature.featureValue.multiArrayValue {
                    
                    let confShape = confidenceMultiArray.shape.map { $0.intValue }
                    let coordShape = coordinatesMultiArray.shape.map { $0.intValue }
                    
                    guard confShape.count >= 2, coordShape.count >= 2 else { return }
                    
                    let numDetections = confShape[0]
                    let numClasses = confShape[1]
                    let classesToCheck = min(numClasses, 6)
                    
                    for i in 0..<numDetections {
                        var maxConfidence: Float = 0.0
                        var bestClassId = 0
                        
                        for classId in 0..<classesToCheck {
                            let confIndex = [i, classId] as [NSNumber]
                            let conf = confidenceMultiArray[confIndex].floatValue
                            if conf > maxConfidence {
                                maxConfidence = conf
                                bestClassId = classId
                            }
                        }
                        
                        guard maxConfidence >= confidenceThreshold else { continue }
                        guard let acneType = AcneType.from(label: String(bestClassId)) else { continue }
                        
                        let cx = coordinatesMultiArray[[i, 0] as [NSNumber]].floatValue
                        let cy = coordinatesMultiArray[[i, 1] as [NSNumber]].floatValue
                        let w = coordinatesMultiArray[[i, 2] as [NSNumber]].floatValue
                        let h = coordinatesMultiArray[[i, 3] as [NSNumber]].floatValue
                        
                        let scale: Float = (cx > 1.0 || cy > 1.0 || w > 1.0 || h > 1.0) ? 640.0 : 1.0
                        let val0 = cx / scale
                        let val1 = cy / scale
                        let val2 = w / scale
                        let val3 = h / scale
                        
                        let rectX = val0 - val2 / 2.0
                        let rectY = 1.0 - (val1 + val3 / 2.0)
                        
                        let boundingBox = CGRect(
                            x: CGFloat(max(0.0, min(1.0, rectX))),
                            y: CGFloat(max(0.0, min(1.0, rectY))),
                            width: CGFloat(max(0.0, min(1.0, val2))),
                            height: CGFloat(max(0.0, min(1.0, val3)))
                        )
                        
                        detections.append(
                            AcneDetection(
                                acneType: acneType,
                                confidence: maxConfidence,
                                boundingBox: boundingBox
                            )
                        )
                    }
                }
                // Single MultiArray legacy fallback (e.g. var_1441)
                else if let firstFeature = features.first,
                        let multiArray = firstFeature.featureValue.multiArrayValue {
                    
                    let shape = multiArray.shape.map { $0.intValue }
                    guard shape.count >= 2 else { return }

                    let numDetections = shape[shape.count - 2]
                    let numFeatures = shape.last ?? 0
                    guard numFeatures >= 5 else { return }

                    for i in 0..<numDetections {
                        let makeIndex: (Int) -> [NSNumber] = { featIndex in
                            shape.count == 3 ? [0, i, featIndex] as [NSNumber] : [i, featIndex] as [NSNumber]
                        }

                        let x = multiArray[makeIndex(0)].floatValue
                        let y = multiArray[makeIndex(1)].floatValue
                        let w = multiArray[makeIndex(2)].floatValue
                        let h = multiArray[makeIndex(3)].floatValue
                        let confidence = multiArray[makeIndex(4)].floatValue

                        guard confidence >= confidenceThreshold else { continue }
                        let classId = numFeatures > 5 ? multiArray[makeIndex(5)].intValue : 0
                        guard let acneType = AcneType.from(label: String(classId)) else { continue }

                        let scale: Float = (x > 1.0 || y > 1.0 || w > 1.0 || h > 1.0) ? 640.0 : 1.0
                        let val0 = x / scale
                        let val1 = y / scale
                        let val2 = w / scale
                        let val3 = h / scale

                        let cx: Float
                        let cy: Float
                        let boxW: Float
                        let boxH: Float

                        if val2 > val0 && val3 > val1 {
                            boxW = val2 - val0
                            boxH = val3 - val1
                            cx = val0 + boxW / 2.0
                            cy = val1 + boxH / 2.0
                        } else {
                            cx = val0
                            cy = val1
                            boxW = val2
                            boxH = val3
                        }

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
            } else {
                print("[AcneDetectionService] Unrecognized or empty request result type: \(type(of: results))")
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("[AcneDetectionService] handler.perform error: \(error)")
            throw error
        }

        if let error = executionError {
            throw error
        }

        print("[AcneDetectionService] Detection finished. Total detections: \(detections.count)")
        return detections
    }

    private nonisolated static func findModelURL(for name: String) throws -> URL {
        if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            return url
        }
        
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
