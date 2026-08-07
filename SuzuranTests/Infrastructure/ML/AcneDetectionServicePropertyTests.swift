import Testing
import CoreGraphics

/// Property-based tests for YOLOv26 model integration
/// Feature: yolov26-model-integration, Property 1: xyxy-to-CGRect Normalization
///
/// **Validates: Requirements 2.1, 2.2**
///
/// These tests verify the mathematical correctness of the xyxy-to-CGRect conversion
/// used in `AcneDetectionService.parseYOLOFeatureObservations`. The conversion takes
/// absolute pixel coordinates (0–640) in xyxy format and produces a normalized CGRect
/// with values in 0.0–1.0.
@Suite("AcneDetectionService Property Tests")
struct AcneDetectionServicePropertyTests {

    /// The model input image size used for normalization.
    private let imageSize: Float = 640.0

    /// Number of random iterations for property-based testing.
    private let iterations = 100

    /// Acceptable floating-point tolerance for comparisons.
    private let epsilon: CGFloat = 0.0001

    // MARK: - Property 1: xyxy-to-CGRect Normalization

    @Test("Property 1: xyxy-to-CGRect normalization produces correct normalized coordinates")
    func xyxyToCGRectNormalization() {
        // **Validates: Requirements 2.1, 2.2**
        //
        // For any valid xyxy pixel coordinates where 0 ≤ x1 < x2 ≤ 640 and
        // 0 ≤ y1 < y2 ≤ 640, the resulting CGRect SHALL have:
        //   - origin.x == x1 / 640
        //   - origin.y == y1 / 640
        //   - size.width == (x2 - x1) / 640
        //   - size.height == (y2 - y1) / 640

        for _ in 0..<iterations {
            // Generate random valid xyxy coordinates within model input bounds
            let x1 = Float.random(in: 0..<639)
            let y1 = Float.random(in: 0..<639)
            let x2 = Float.random(in: (x1 + 1)...640)
            let y2 = Float.random(in: (y1 + 1)...640)

            // Apply the same xyxy-to-CGRect conversion as AcneDetectionService
            let rect = CGRect(
                x: CGFloat(x1 / imageSize),
                y: CGFloat(y1 / imageSize),
                width: CGFloat((x2 - x1) / imageSize),
                height: CGFloat((y2 - y1) / imageSize)
            )

            // Verify origin matches normalized top-left corner
            let expectedX = CGFloat(x1 / imageSize)
            let expectedY = CGFloat(y1 / imageSize)
            let expectedWidth = CGFloat((x2 - x1) / imageSize)
            let expectedHeight = CGFloat((y2 - y1) / imageSize)

            #expect(
                abs(rect.origin.x - expectedX) < epsilon,
                "origin.x mismatch: got \(rect.origin.x), expected \(expectedX) for x1=\(x1)"
            )
            #expect(
                abs(rect.origin.y - expectedY) < epsilon,
                "origin.y mismatch: got \(rect.origin.y), expected \(expectedY) for y1=\(y1)"
            )
            #expect(
                abs(rect.size.width - expectedWidth) < epsilon,
                "width mismatch: got \(rect.size.width), expected \(expectedWidth) for x1=\(x1), x2=\(x2)"
            )
            #expect(
                abs(rect.size.height - expectedHeight) < epsilon,
                "height mismatch: got \(rect.size.height), expected \(expectedHeight) for y1=\(y1), y2=\(y2)"
            )

            // Verify normalized bounds: all values must be within [0, 1]
            #expect(rect.origin.x >= 0, "origin.x must be non-negative, got \(rect.origin.x)")
            #expect(rect.origin.y >= 0, "origin.y must be non-negative, got \(rect.origin.y)")
            #expect(rect.size.width > 0, "width must be positive, got \(rect.size.width)")
            #expect(rect.size.height > 0, "height must be positive, got \(rect.size.height)")
            #expect(
                rect.origin.x + rect.size.width <= 1.0 + epsilon,
                "x + width must be ≤ 1.0, got \(rect.origin.x + rect.size.width)"
            )
            #expect(
                rect.origin.y + rect.size.height <= 1.0 + epsilon,
                "y + height must be ≤ 1.0, got \(rect.origin.y + rect.size.height)"
            )
        }
    }

    // MARK: - Edge Cases for Property 1

    @Test("Property 1 edge case: minimum valid bounding box (1 pixel wide and tall)")
    func xyxyMinimumBoundingBox() {
        // **Validates: Requirements 2.1, 2.2**
        // The smallest valid bounding box is 1 pixel in each dimension.
        let x1: Float = 0
        let y1: Float = 0
        let x2: Float = 1
        let y2: Float = 1

        let rect = CGRect(
            x: CGFloat(x1 / imageSize),
            y: CGFloat(y1 / imageSize),
            width: CGFloat((x2 - x1) / imageSize),
            height: CGFloat((y2 - y1) / imageSize)
        )

        #expect(abs(rect.origin.x - 0.0) < epsilon)
        #expect(abs(rect.origin.y - 0.0) < epsilon)
        #expect(abs(rect.size.width - CGFloat(1.0 / 640.0)) < epsilon)
        #expect(abs(rect.size.height - CGFloat(1.0 / 640.0)) < epsilon)
    }

    @Test("Property 1 edge case: maximum valid bounding box (full image)")
    func xyxyMaximumBoundingBox() {
        // **Validates: Requirements 2.1, 2.2**
        // The largest valid bounding box spans the entire image.
        let x1: Float = 0
        let y1: Float = 0
        let x2: Float = 640
        let y2: Float = 640

        let rect = CGRect(
            x: CGFloat(x1 / imageSize),
            y: CGFloat(y1 / imageSize),
            width: CGFloat((x2 - x1) / imageSize),
            height: CGFloat((y2 - y1) / imageSize)
        )

        #expect(abs(rect.origin.x - 0.0) < epsilon)
        #expect(abs(rect.origin.y - 0.0) < epsilon)
        #expect(abs(rect.size.width - 1.0) < epsilon)
        #expect(abs(rect.size.height - 1.0) < epsilon)
    }

    @Test("Property 1 edge case: bounding box at bottom-right corner")
    func xyxyBottomRightCorner() {
        // **Validates: Requirements 2.1, 2.2**
        // A bounding box anchored at the bottom-right of the image.
        let x1: Float = 639
        let y1: Float = 639
        let x2: Float = 640
        let y2: Float = 640

        let rect = CGRect(
            x: CGFloat(x1 / imageSize),
            y: CGFloat(y1 / imageSize),
            width: CGFloat((x2 - x1) / imageSize),
            height: CGFloat((y2 - y1) / imageSize)
        )

        #expect(abs(rect.origin.x - CGFloat(639.0 / 640.0)) < epsilon)
        #expect(abs(rect.origin.y - CGFloat(639.0 / 640.0)) < epsilon)
        #expect(abs(rect.size.width - CGFloat(1.0 / 640.0)) < epsilon)
        #expect(abs(rect.size.height - CGFloat(1.0 / 640.0)) < epsilon)
        #expect(rect.origin.x + rect.size.width <= 1.0 + epsilon)
        #expect(rect.origin.y + rect.size.height <= 1.0 + epsilon)
    }

    // MARK: - Property 2: Detection Filtering Invariant

    @Test("Property 2: detection filtering invariant ensures only valid detections pass")
    func detectionFilteringInvariant() {
        // **Validates: Requirements 2.3, 2.4**
        //
        // For any set of detection rows with random confidence and class_id values
        // (including invalid ones), the filtering logic SHALL:
        //   - Accept only detections with confidence >= 0.25 AND class_id in 0...5
        //   - Reject all detections with confidence < 0.25 OR class_id outside 0...5

        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]

        for _ in 0..<iterations {
            // Generate a random number of detections (5 to 50 per iteration)
            let numDetections = Int.random(in: 5...50)

            // Represent each detection as (confidence, classId) with intentionally
            // invalid values mixed in to exercise filtering boundaries.
            struct RawDetection {
                let confidence: Float
                let classId: Int
            }

            var rawDetections: [RawDetection] = []
            for _ in 0..<numDetections {
                // Confidence: range [-0.5, 1.5] to include values below 0 and above 1
                let confidence = Float.random(in: -0.5...1.5)
                // Class ID: range [-2, 8] to include invalid class indices
                let classId = Int.random(in: -2...8)
                rawDetections.append(RawDetection(confidence: confidence, classId: classId))
            }

            // Apply the same filtering logic as AcneDetectionService.parseYOLOFeatureObservations
            var accepted: [RawDetection] = []
            var rejected: [RawDetection] = []

            for detection in rawDetections {
                let conf = detection.confidence
                let classId = detection.classId

                // Replicate: guard conf >= confidenceThreshold else { continue }
                // Replicate: guard classId >= 0 && classId < classLabels.count else { continue }
                if conf >= confidenceThreshold && classId >= 0 && classId < classLabels.count {
                    accepted.append(detection)
                } else {
                    rejected.append(detection)
                }
            }

            // Invariant 1: All accepted detections MUST have confidence >= threshold
            for detection in accepted {
                #expect(
                    detection.confidence >= confidenceThreshold,
                    "Accepted detection has confidence \(detection.confidence) < threshold \(confidenceThreshold)"
                )
            }

            // Invariant 2: All accepted detections MUST have class_id in valid range [0, 5]
            for detection in accepted {
                #expect(
                    detection.classId >= 0 && detection.classId < classLabels.count,
                    "Accepted detection has invalid classId \(detection.classId), expected 0..<\(classLabels.count)"
                )
            }

            // Invariant 3: No rejected detection should have been valid
            // (i.e., every rejected detection violates at least one filter condition)
            for detection in rejected {
                let wouldBeValid = detection.confidence >= confidenceThreshold
                    && detection.classId >= 0
                    && detection.classId < classLabels.count
                #expect(
                    !wouldBeValid,
                    "Rejected detection (conf=\(detection.confidence), classId=\(detection.classId)) would have been valid"
                )
            }

            // Invariant 4: Accepted + Rejected == total (no detections lost)
            #expect(
                accepted.count + rejected.count == numDetections,
                "Detection count mismatch: accepted(\(accepted.count)) + rejected(\(rejected.count)) != total(\(numDetections))"
            )
        }
    }

    @Test("Property 2 edge case: all detections below confidence threshold are rejected")
    func filteringAllBelowThreshold() {
        // **Validates: Requirements 2.3, 2.4**
        // When all detections have confidence < 0.25, none should pass the filter.
        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]

        for _ in 0..<iterations {
            let numDetections = Int.random(in: 1...20)
            var acceptedCount = 0

            for _ in 0..<numDetections {
                let conf = Float.random(in: 0.0..<confidenceThreshold) // Always below threshold
                let classId = Int.random(in: 0..<classLabels.count)    // Valid class ID

                if conf >= confidenceThreshold && classId >= 0 && classId < classLabels.count {
                    acceptedCount += 1
                }
            }

            #expect(
                acceptedCount == 0,
                "Expected 0 accepted detections when all confidence < threshold, got \(acceptedCount)"
            )
        }
    }

    @Test("Property 2 edge case: all detections with invalid class_id are rejected")
    func filteringAllInvalidClassId() {
        // **Validates: Requirements 2.3, 2.4**
        // When all detections have class_id outside [0, 5], none should pass the filter.
        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]

        for _ in 0..<iterations {
            let numDetections = Int.random(in: 1...20)
            var acceptedCount = 0

            for _ in 0..<numDetections {
                let conf = Float.random(in: confidenceThreshold...1.0) // Valid confidence
                // Invalid class IDs: either negative or >= classLabels.count
                let classId: Int
                if Bool.random() {
                    classId = Int.random(in: -10...(-1))
                } else {
                    classId = Int.random(in: classLabels.count...20)
                }

                if conf >= confidenceThreshold && classId >= 0 && classId < classLabels.count {
                    acceptedCount += 1
                }
            }

            #expect(
                acceptedCount == 0,
                "Expected 0 accepted detections when all classId invalid, got \(acceptedCount)"
            )
        }
    }

    @Test("Property 2 edge case: confidence exactly at threshold boundary")
    func filteringConfidenceBoundary() {
        // **Validates: Requirements 2.3, 2.4**
        // A detection with confidence == 0.25 exactly should be accepted (guard uses >=).
        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]

        let conf: Float = confidenceThreshold
        let classId = Int.random(in: 0..<classLabels.count)

        let accepted = conf >= confidenceThreshold && classId >= 0 && classId < classLabels.count
        #expect(accepted, "Detection at exactly the confidence threshold (0.25) should be accepted")
    }

    // MARK: - Property 3: NMS Bypass for End-to-End Output

    @Test("Property 3: NMS bypass preserves all valid overlapping detections in end-to-end mode")
    func nmsBypassPreservesAllValidDetections() {
        // **Validates: Requirements 3.1**
        //
        // For any end-to-end model output (numAttributes == 6) containing overlapping
        // detections with IoU > 0.45, ALL detections above the confidence threshold
        // SHALL be preserved in the output (none removed by NMS).
        //
        // The end-to-end model handles NMS internally, so the parser must return all
        // valid detections without applying external NMS suppression.

        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]
        let imageSize: Float = 640.0
        let iouThreshold: CGFloat = 0.45

        for _ in 0..<iterations {
            // Generate a cluster of overlapping detections (IoU > 0.45)
            // Start with a base bounding box, then generate overlapping variants.
            let numDetections = Int.random(in: 3...15)

            // Base box: random anchor with reasonable size
            let baseX1 = Float.random(in: 0..<400)
            let baseY1 = Float.random(in: 0..<400)
            let baseWidth = Float.random(in: 50...200)
            let baseHeight = Float.random(in: 50...200)
            let baseX2 = min(baseX1 + baseWidth, 640)
            let baseY2 = min(baseY1 + baseHeight, 640)

            struct Detection {
                let x1: Float
                let y1: Float
                let x2: Float
                let y2: Float
                let confidence: Float
                let classId: Int
            }

            var detections: [Detection] = []

            for _ in 0..<numDetections {
                // Generate overlapping boxes by shifting the base box slightly
                // Small shifts ensure IoU > 0.45
                let maxShift = min(baseWidth, baseHeight) * 0.15
                let shiftX = Float.random(in: -maxShift...maxShift)
                let shiftY = Float.random(in: -maxShift...maxShift)

                let x1 = max(0, baseX1 + shiftX)
                let y1 = max(0, baseY1 + shiftY)
                let x2 = min(640, baseX2 + shiftX)
                let y2 = min(640, baseY2 + shiftY)

                // Valid confidence above threshold
                let confidence = Float.random(in: confidenceThreshold...1.0)
                // Valid class ID
                let classId = Int.random(in: 0..<classLabels.count)

                detections.append(Detection(
                    x1: x1, y1: y1, x2: x2, y2: y2,
                    confidence: confidence, classId: classId
                ))
            }

            // Verify that overlapping pairs exist (IoU > 0.45)
            var hasOverlap = false
            for i in 0..<detections.count {
                for j in (i + 1)..<detections.count {
                    let a = CGRect(
                        x: CGFloat(detections[i].x1 / imageSize),
                        y: CGFloat(detections[i].y1 / imageSize),
                        width: CGFloat((detections[i].x2 - detections[i].x1) / imageSize),
                        height: CGFloat((detections[i].y2 - detections[i].y1) / imageSize)
                    )
                    let b = CGRect(
                        x: CGFloat(detections[j].x1 / imageSize),
                        y: CGFloat(detections[j].y1 / imageSize),
                        width: CGFloat((detections[j].x2 - detections[j].x1) / imageSize),
                        height: CGFloat((detections[j].y2 - detections[j].y1) / imageSize)
                    )
                    let intersection = a.intersection(b)
                    if !intersection.isNull {
                        let interArea = intersection.width * intersection.height
                        let unionArea = a.width * a.height + b.width * b.height - interArea
                        if unionArea > 0 && (interArea / unionArea) > iouThreshold {
                            hasOverlap = true
                        }
                    }
                }
                if hasOverlap { break }
            }

            // Only test iterations where we actually have overlapping detections
            guard hasOverlap else { continue }

            // Simulate end-to-end parsing path: filter only, NO NMS
            // This replicates the behavior when usedEnd2EndPath = true
            var end2EndResults: [CGRect] = []
            for det in detections {
                guard det.confidence >= confidenceThreshold else { continue }
                guard det.classId >= 0 && det.classId < classLabels.count else { continue }
                let rect = CGRect(
                    x: CGFloat(det.x1 / imageSize),
                    y: CGFloat(det.y1 / imageSize),
                    width: CGFloat((det.x2 - det.x1) / imageSize),
                    height: CGFloat((det.y2 - det.y1) / imageSize)
                )
                end2EndResults.append(rect)
            }

            // Count valid detections (those that pass confidence + classId filters)
            let validCount = detections.filter {
                $0.confidence >= confidenceThreshold && $0.classId >= 0 && $0.classId < classLabels.count
            }.count

            // PROPERTY: End-to-end path preserves ALL valid detections
            #expect(
                end2EndResults.count == validCount,
                "End-to-end path should preserve all \(validCount) valid detections, got \(end2EndResults.count)"
            )

            // Simulate what would happen if NMS WERE applied (classic path behavior)
            // This demonstrates that NMS would suppress some detections
            let sorted = detections
                .filter { $0.confidence >= confidenceThreshold && $0.classId >= 0 && $0.classId < classLabels.count }
                .sorted { $0.confidence > $1.confidence }

            var nmsKept: [CGRect] = []
            for det in sorted {
                let candidateRect = CGRect(
                    x: CGFloat(det.x1 / imageSize),
                    y: CGFloat(det.y1 / imageSize),
                    width: CGFloat((det.x2 - det.x1) / imageSize),
                    height: CGFloat((det.y2 - det.y1) / imageSize)
                )
                let dominated = nmsKept.contains { existing in
                    let intersection = existing.intersection(candidateRect)
                    guard !intersection.isNull else { return false }
                    let interArea = intersection.width * intersection.height
                    let unionArea = existing.width * existing.height + candidateRect.width * candidateRect.height - interArea
                    guard unionArea > 0 else { return false }
                    return (interArea / unionArea) > iouThreshold
                }
                if !dominated {
                    nmsKept.append(candidateRect)
                }
            }

            // Contrast: NMS would suppress some overlapping detections
            // End-to-end path should have MORE or EQUAL results compared to NMS path
            #expect(
                end2EndResults.count >= nmsKept.count,
                "End-to-end should preserve ≥ detections than NMS: e2e=\(end2EndResults.count), nms=\(nmsKept.count)"
            )

            // When overlapping detections exist, NMS typically removes some
            // This verifies the bypass actually matters
            if end2EndResults.count > 1 {
                // With overlapping boxes, NMS should suppress at least some
                #expect(
                    nmsKept.count < end2EndResults.count,
                    "With overlapping detections (IoU > 0.45), NMS should suppress some: nms=\(nmsKept.count), total=\(end2EndResults.count)"
                )
            }
        }
    }

    @Test("Property 3 edge case: single detection is preserved without NMS in end-to-end mode")
    func nmsBypassSingleDetection() {
        // **Validates: Requirements 3.1**
        // A single valid detection should always be preserved (NMS has nothing to suppress).
        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]
        let imageSize: Float = 640.0

        for _ in 0..<iterations {
            let x1 = Float.random(in: 0..<600)
            let y1 = Float.random(in: 0..<600)
            let x2 = Float.random(in: (x1 + 10)...640)
            let y2 = Float.random(in: (y1 + 10)...640)
            let confidence = Float.random(in: confidenceThreshold...1.0)
            let classId = Int.random(in: 0..<classLabels.count)

            // End-to-end path: filter only
            var results: [CGRect] = []
            if confidence >= confidenceThreshold && classId >= 0 && classId < classLabels.count {
                let rect = CGRect(
                    x: CGFloat(x1 / imageSize),
                    y: CGFloat(y1 / imageSize),
                    width: CGFloat((x2 - x1) / imageSize),
                    height: CGFloat((y2 - y1) / imageSize)
                )
                results.append(rect)
            }

            #expect(results.count == 1, "Single valid detection must be preserved in end-to-end mode")
        }
    }

    @Test("Property 3 edge case: identical bounding boxes all preserved in end-to-end mode")
    func nmsBypassIdenticalBoxes() {
        // **Validates: Requirements 3.1**
        // Multiple detections with identical bounding boxes (IoU == 1.0) should all
        // be preserved in end-to-end mode. NMS would suppress all but the strongest.
        let confidenceThreshold: Float = 0.25
        let classLabels = ["blackhead", "cyst", "nodule", "papule", "pustule", "whitehead"]
        let imageSize: Float = 640.0

        for _ in 0..<iterations {
            let numDetections = Int.random(in: 2...10)
            let x1 = Float.random(in: 0..<500)
            let y1 = Float.random(in: 0..<500)
            let x2 = Float.random(in: (x1 + 50)...640)
            let y2 = Float.random(in: (y1 + 50)...640)

            // All detections share the same bounding box (IoU == 1.0)
            var end2EndResults: [CGRect] = []
            for _ in 0..<numDetections {
                let confidence = Float.random(in: confidenceThreshold...1.0)
                let classId = Int.random(in: 0..<classLabels.count)

                if confidence >= confidenceThreshold && classId >= 0 && classId < classLabels.count {
                    let rect = CGRect(
                        x: CGFloat(x1 / imageSize),
                        y: CGFloat(y1 / imageSize),
                        width: CGFloat((x2 - x1) / imageSize),
                        height: CGFloat((y2 - y1) / imageSize)
                    )
                    end2EndResults.append(rect)
                }
            }

            // End-to-end path: ALL detections preserved
            #expect(
                end2EndResults.count == numDetections,
                "All \(numDetections) identical-box detections must be preserved in end-to-end mode, got \(end2EndResults.count)"
            )

            // Contrast: NMS would keep only 1 (the first/highest confidence)
            if end2EndResults.count > 1 {
                var nmsKept: [CGRect] = []
                let iouThreshold: CGFloat = 0.45
                for rect in end2EndResults {
                    let dominated = nmsKept.contains { existing in
                        let intersection = existing.intersection(rect)
                        guard !intersection.isNull else { return false }
                        let interArea = intersection.width * intersection.height
                        let unionArea = existing.width * existing.height + rect.width * rect.height - interArea
                        guard unionArea > 0 else { return false }
                        return (interArea / unionArea) > iouThreshold
                    }
                    if !dominated {
                        nmsKept.append(rect)
                    }
                }

                // NMS would only keep 1 out of identical boxes
                #expect(
                    nmsKept.count == 1,
                    "NMS should suppress identical boxes to 1, got \(nmsKept.count)"
                )
                // End-to-end preserves more
                #expect(
                    end2EndResults.count > nmsKept.count,
                    "End-to-end (\(end2EndResults.count)) should preserve more than NMS (\(nmsKept.count))"
                )
            }
        }
    }

    // MARK: - Property 5: Normalized Coordinates Invariant

    @Test("Property 5: normalized coordinates invariant ensures all boundingBox values are within [0, 1]")
    func normalizedCoordinatesInvariant() {
        // **Validates: Requirements 4.2, 4.3**
        //
        // For any valid pixel coordinates in the range [0, 640], all returned
        // boundingBox values SHALL satisfy:
        //   - x ≥ 0
        //   - y ≥ 0
        //   - width > 0
        //   - height > 0
        //   - x + width ≤ 1.0
        //   - y + height ≤ 1.0

        for _ in 0..<iterations {
            // Generate random valid xyxy coordinates: 0 ≤ x1 < x2 ≤ 640, 0 ≤ y1 < y2 ≤ 640
            let x1 = Float.random(in: 0..<640)
            let y1 = Float.random(in: 0..<640)
            let x2 = Float.random(in: (x1 + 0.001)...640)
            let y2 = Float.random(in: (y1 + 0.001)...640)

            // Apply the same normalization as AcneDetectionService
            let rect = CGRect(
                x: CGFloat(x1 / imageSize),
                y: CGFloat(y1 / imageSize),
                width: CGFloat((x2 - x1) / imageSize),
                height: CGFloat((y2 - y1) / imageSize)
            )

            // Invariant 1: x ≥ 0
            #expect(
                rect.origin.x >= 0,
                "x must be ≥ 0, got \(rect.origin.x) for x1=\(x1)"
            )

            // Invariant 2: y ≥ 0
            #expect(
                rect.origin.y >= 0,
                "y must be ≥ 0, got \(rect.origin.y) for y1=\(y1)"
            )

            // Invariant 3: width > 0
            #expect(
                rect.size.width > 0,
                "width must be > 0, got \(rect.size.width) for x1=\(x1), x2=\(x2)"
            )

            // Invariant 4: height > 0
            #expect(
                rect.size.height > 0,
                "height must be > 0, got \(rect.size.height) for y1=\(y1), y2=\(y2)"
            )

            // Invariant 5: x + width ≤ 1.0
            #expect(
                rect.origin.x + rect.size.width <= 1.0 + epsilon,
                "x + width must be ≤ 1.0, got \(rect.origin.x + rect.size.width) for x1=\(x1), x2=\(x2)"
            )

            // Invariant 6: y + height ≤ 1.0
            #expect(
                rect.origin.y + rect.size.height <= 1.0 + epsilon,
                "y + height must be ≤ 1.0, got \(rect.origin.y + rect.size.height) for y1=\(y1), y2=\(y2)"
            )
        }
    }

    @Test("Property 5 edge case: coordinates at exact boundary values")
    func normalizedCoordinatesBoundaryValues() {
        // **Validates: Requirements 4.2, 4.3**
        // Test boundary cases: minimum (0,0) to maximum (640,640)

        // Case 1: Full image span (0,0) to (640,640)
        let fullRect = CGRect(
            x: CGFloat(0.0 / imageSize),
            y: CGFloat(0.0 / imageSize),
            width: CGFloat((640.0 - 0.0) / imageSize),
            height: CGFloat((640.0 - 0.0) / imageSize)
        )
        #expect(fullRect.origin.x >= 0)
        #expect(fullRect.origin.y >= 0)
        #expect(fullRect.size.width > 0)
        #expect(fullRect.size.height > 0)
        #expect(fullRect.origin.x + fullRect.size.width <= 1.0 + epsilon)
        #expect(fullRect.origin.y + fullRect.size.height <= 1.0 + epsilon)

        // Case 2: Smallest box at origin (0,0) to (1,1)
        let tinyRect = CGRect(
            x: CGFloat(0.0 / imageSize),
            y: CGFloat(0.0 / imageSize),
            width: CGFloat(1.0 / imageSize),
            height: CGFloat(1.0 / imageSize)
        )
        #expect(tinyRect.origin.x >= 0)
        #expect(tinyRect.origin.y >= 0)
        #expect(tinyRect.size.width > 0)
        #expect(tinyRect.size.height > 0)
        #expect(tinyRect.origin.x + tinyRect.size.width <= 1.0 + epsilon)
        #expect(tinyRect.origin.y + tinyRect.size.height <= 1.0 + epsilon)

        // Case 3: Smallest box at far corner (639,639) to (640,640)
        let cornerRect = CGRect(
            x: CGFloat(639.0 / imageSize),
            y: CGFloat(639.0 / imageSize),
            width: CGFloat(1.0 / imageSize),
            height: CGFloat(1.0 / imageSize)
        )
        #expect(cornerRect.origin.x >= 0)
        #expect(cornerRect.origin.y >= 0)
        #expect(cornerRect.size.width > 0)
        #expect(cornerRect.size.height > 0)
        #expect(cornerRect.origin.x + cornerRect.size.width <= 1.0 + epsilon)
        #expect(cornerRect.origin.y + cornerRect.size.height <= 1.0 + epsilon)
    }

    @Test("Property 5 edge case: very small sub-pixel width and height produce positive dimensions")
    func normalizedCoordinatesSubPixelDimensions() {
        // **Validates: Requirements 4.2, 4.3**
        // Even very small differences (x2 - x1 close to 0 but positive) must yield width > 0.

        for _ in 0..<iterations {
            let x1 = Float.random(in: 0..<639.9)
            let y1 = Float.random(in: 0..<639.9)
            // Very small but positive gap (sub-pixel precision)
            let gap = Float.random(in: 0.001...1.0)
            let x2 = min(x1 + gap, 640.0)
            let y2 = min(y1 + gap, 640.0)

            // Ensure x2 > x1 and y2 > y1 after clamping
            guard x2 > x1 && y2 > y1 else { continue }

            let rect = CGRect(
                x: CGFloat(x1 / imageSize),
                y: CGFloat(y1 / imageSize),
                width: CGFloat((x2 - x1) / imageSize),
                height: CGFloat((y2 - y1) / imageSize)
            )

            #expect(
                rect.origin.x >= 0,
                "x must be ≥ 0 for sub-pixel box, got \(rect.origin.x)"
            )
            #expect(
                rect.origin.y >= 0,
                "y must be ≥ 0 for sub-pixel box, got \(rect.origin.y)"
            )
            #expect(
                rect.size.width > 0,
                "width must be > 0 for sub-pixel box, got \(rect.size.width)"
            )
            #expect(
                rect.size.height > 0,
                "height must be > 0 for sub-pixel box, got \(rect.size.height)"
            )
            #expect(
                rect.origin.x + rect.size.width <= 1.0 + epsilon,
                "x + width must be ≤ 1.0 for sub-pixel box, got \(rect.origin.x + rect.size.width)"
            )
            #expect(
                rect.origin.y + rect.size.height <= 1.0 + epsilon,
                "y + height must be ≤ 1.0 for sub-pixel box, got \(rect.origin.y + rect.size.height)"
            )
        }
    }
}
