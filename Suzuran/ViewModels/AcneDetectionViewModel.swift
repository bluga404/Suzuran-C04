//
//  AcneDetectionViewModel.swift
//  Suzuran — ViewModels/
//
//  Drives the YOLOv8 acne-detection CoreML pipeline.
//

import Combine
import CoreML
import Vision
import UIKit
import ARKit

private struct RawDetection {
    let acneClass: AcneClass
    let confidence: Float
    let normalizedBox: CGRect
}

final class AcneDetectionViewModel: ObservableObject {

    // MARK: - Published State

    /// Accumulated detections across all angles, deduplicated in 3D.
    @Published var detections: [AcneDetectionResult] = []
    
    /// True while inference is running.
    @Published var isAnalyzing: Bool         = false
    
    /// Non-nil if the model failed to load or inference failed.
    @Published var analysisError: String?    = nil

    // MARK: - Pipeline Constants

    private let confidenceThreshold: Float = 0.20
    private let iouThreshold:        Float = 0.45
    private let maxDetections:       Int   = 50
    private let mergeDistanceSq:     Float = 0.008 * 0.008 // 0.8 cm merge radius

    // MARK: - Model

    private let visionModel: VNCoreMLModel?

    // MARK: - Init

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        do {
            let coreMLModel = try best(configuration: config)
            visionModel = try VNCoreMLModel(for: coreMLModel.model)
        } catch {
            visionModel = nil
            print("⚠️ AcneDetectionViewModel: model load failed — \(error)")
        }
    }

    // MARK: - Public API

    /// Runs the detection pipeline on a captured ARSnapshot.
    func analyse(snapshot: ARSnapshot) {
        guard !isAnalyzing else { return }

        DispatchQueue.main.async { [weak self] in
            self?.isAnalyzing   = true
            self?.analysisError = nil
        }

        guard let model = visionModel else {
            DispatchQueue.main.async { [weak self] in
                self?.analysisError = "Detection model unavailable. Please rebuild the project."
                self?.isAnalyzing   = false
            }
            return
        }

        // Run inference off the main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                let rawResults = try self.runInference(on: snapshot.pixelBuffer, model: model)
                let mappedResults = self.mapTo3D(rawDetections: rawResults, snapshot: snapshot)
                
                DispatchQueue.main.async { [weak self] in
                    self?.mergeDetections(mappedResults)
                    self?.isAnalyzing = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.analysisError = "Inference failed: \(error.localizedDescription)"
                    self?.isAnalyzing   = false
                }
            }
        }
    }

    // MARK: - Inference

    private func runInference(on pixelBuffer: CVPixelBuffer, model: VNCoreMLModel) throws -> [RawDetection] {
        var raw: [RawDetection] = []

        let request = VNCoreMLRequest(model: model) { [weak self] req, _ in
            guard let self,
                  let observations = req.results as? [VNCoreMLFeatureValueObservation],
                  let mlArray = observations.first?.featureValue.multiArrayValue
            else { return }
            raw = self.decodeOutput(mlArray)
        }
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation:   .right,
            options:       [:]
        )
        try handler.perform([request])

        return raw
    }

    // MARK: - Output Decoding

    private func decodeOutput(_ array: MLMultiArray) -> [RawDetection] {
        guard array.shape.count == 3,
              array.shape[1].intValue == 300,
              array.shape[2].intValue == 6 else {
            print("⚠️ Unexpected output shape: \(array.shape)")
            return []
        }

        let numDetections = 300
        let ptr = array.dataPointer.bindMemory(to: Float32.self, capacity: array.count)

        var candidates: [RawDetection] = []
        candidates.reserveCapacity(numDetections)

        for i in 0..<numDetections {
            // Memory layout: [batch=1, numDetections=300, features=6]
            // C-contiguous offset: i * 6 + feature_index
            let offset = i * 6
            
            let val0  = CGFloat(ptr[offset + 0])
            let val1  = CGFloat(ptr[offset + 1])
            let val2  = CGFloat(ptr[offset + 2])
            let val3  = CGFloat(ptr[offset + 3])
            let conf  = ptr[offset + 4]
            let clsId = Int(ptr[offset + 5])

            // If confidence is 0 (or below threshold), this is a padded/empty detection
            guard conf >= confidenceThreshold else { continue }
            guard let acneClass = AcneClass(rawValue: clsId) else { continue }

            // Baked-in NMS typically outputs [x1, y1, x2, y2, conf, cls] 
            // We dynamically check if it's in pixels (0-640) or already normalized (0-1)
            let scale: CGFloat = (val0 > 1.0 || val2 > 1.0) ? 640.0 : 1.0
            
            // Assume [x1, y1, x2, y2]
            var nx = val0 / scale
            var ny = val1 / scale
            var nw = (val2 - val0) / scale
            var nh = (val3 - val1) / scale
            
            // Fallback: if it was actually [cx, cy, w, h], nw would be negative or wildly off if we did x2 - x1
            // But usually w,h are positive. If val2 is width (e.g. 50), val0 is cx (e.g. 300)
            // Then val2 - val0 = 50 - 300 = -250.
            if nw < 0 {
                // It was [cx, cy, w, h] after all
                let cx = val0 / scale
                let cy = val1 / scale
                let w  = val2 / scale
                let h  = val3 / scale
                nx = cx - w / 2
                ny = cy - h / 2
                nw = w
                nh = h
            }

            let box = CGRect(x: max(0, nx), y: max(0, ny),
                             width:  min(nw, 1 - max(0, nx)),
                             height: min(nh, 1 - max(0, ny)))
            guard box.width > 0.01, box.height > 0.01 else { continue }

            candidates.append(RawDetection(
                acneClass:     acneClass,
                confidence:    conf,
                normalizedBox: box
            ))
        }

        return candidates
    }

    // MARK: - NMS

    // NMS is no longer needed here as the [1, 300, 6] model output implies NMS is built-in.

    private func iou(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        guard !intersection.isNull,
              intersection.width > 0,
              intersection.height > 0 else { return 0 }
        let i = Float(intersection.width  * intersection.height)
        let u = Float(a.width * a.height) + Float(b.width * b.height) - i
        return u > 0 ? i / u : 0
    }

    // MARK: - 3D Mapping & Deduplication

    private func mapTo3D(rawDetections: [RawDetection], snapshot: ARSnapshot) -> [AcneDetectionResult] {
        var results: [AcneDetectionResult] = []
        
        let width = CGFloat(CVPixelBufferGetWidth(snapshot.pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(snapshot.pixelBuffer))
        let portraitSize = CGSize(width: height, height: width) // Transposed for .right orientation

        // Pre-project all vertices to 2D
        var projectedVertices: [CGPoint] = []
        projectedVertices.reserveCapacity(snapshot.vertices.count)
        
        for vertexLocal in snapshot.vertices {
            let vertexWorld = simd_mul(snapshot.faceTransform, simd_make_float4(vertexLocal, 1.0))
            let point2D = snapshot.camera.projectPoint(
                simd_make_float3(vertexWorld),
                orientation: .portrait,
                viewportSize: portraitSize
            )
            // Normalize
            let nx = point2D.x / portraitSize.width
            let ny = point2D.y / portraitSize.height
            projectedVertices.append(CGPoint(x: nx, y: ny))
        }

        // For each raw detection, find closest vertex
        for det in rawDetections {
            let center = CGPoint(x: det.normalizedBox.midX, y: det.normalizedBox.midY)
            var bestDist: CGFloat = .infinity
            var bestIdx: Int = -1

            for (i, p) in projectedVertices.enumerated() {
                let dx = p.x - center.x
                let dy = p.y - center.y
                let distSq = dx*dx + dy*dy
                if distSq < bestDist {
                    bestDist = distSq
                    bestIdx = i
                }
            }

            if bestIdx >= 0 {
                results.append(AcneDetectionResult(
                    acneClass: det.acneClass,
                    confidence: det.confidence,
                    vertexIndex: bestIdx,
                    localPosition: snapshot.vertices[bestIdx]
                ))
            }
        }
        return results
    }

    private func mergeDetections(_ newDetections: [AcneDetectionResult]) {
        for newDet in newDetections {
            var foundMatch = false
            for (i, existing) in detections.enumerated() {
                let dx = existing.localPosition.x - newDet.localPosition.x
                let dy = existing.localPosition.y - newDet.localPosition.y
                let dz = existing.localPosition.z - newDet.localPosition.z
                let distSq = dx*dx + dy*dy + dz*dz

                if distSq < mergeDistanceSq {
                    foundMatch = true
                    if newDet.confidence > existing.confidence {
                        detections[i] = newDet // Replace with higher confidence
                    }
                    break
                }
            }
            if !foundMatch {
                detections.append(newDet)
            }
        }
    }
}
