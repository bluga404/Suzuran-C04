import Testing
import CoreGraphics

@testable import Suzuran

/// Property-based tests for YOLO tensor parsing and confidence filtering.
/// Feature: face-scan-redesign, Property 4: YOLO Tensor Parsing and Confidence Filtering
///
/// **Validates: Requirements 5.3, 5.4**
///
/// These tests verify that the YOLO end2end parser correctly:
/// - Produces exactly those detections where confidence ≥ 0.05
/// - Filters out detections where class_id ∉ [0, 5]
/// - Correctly extracts bounding box coordinates from the raw tensor
@Suite("YOLO Parser Property Tests")
struct YOLOParserPropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 100

    /// Confidence threshold used by the parser.
    private let confidenceThreshold: Float = 0.05

    // MARK: - Property 4: YOLO Tensor Parsing and Confidence Filtering

    @Test("Property 4: Parser produces exactly detections where confidence ≥ 0.05 AND class_id ∈ [0, 5]")
    func yoloParsing_filteringProperty() {
        // **Validates: Requirements 5.3, 5.4**
        //
        // For any raw float array representing model output of shape [300, 6] with values
        // [x1, y1, x2, y2, confidence, class_id], the parser SHALL produce exactly those
        // detections where confidence ≥ 0.05 AND class_id ∈ [0, 5].

        for _ in 0..<iterations {
            let numDetections = 300
            let numAttributes = 6

            // Generate random tensor data
            var data: [Float] = []
            var expectedCount = 0

            for _ in 0..<numDetections {
                let x1 = Float.random(in: 0...640)
                let y1 = Float.random(in: 0...640)
                let x2 = Float.random(in: 0...640)
                let y2 = Float.random(in: 0...640)
                let confidence = Float.random(in: 0...1)
                let classId = Float(Int.random(in: 0...7))

                data.append(contentsOf: [x1, y1, x2, y2, confidence, classId])

                // Expected: passes both confidence AND class_id filter
                if confidence >= confidenceThreshold && Int(classId) >= 0 && Int(classId) <= 5 {
                    expectedCount += 1
                }
            }

            let result = AcneDetectionService.parseRawDetections(
                from: data,
                numDetections: numDetections
            )

            #expect(
                result.count == expectedCount,
                """
                Detection count mismatch: got \(result.count), expected \(expectedCount).
                The parser must produce exactly those detections where confidence ≥ 0.05 AND class_id ∈ [0, 5].
                """
            )
        }
    }

    @Test("Property 4a: All returned detections have confidence ≥ 0.05")
    func yoloParsing_allReturnedHaveValidConfidence() {
        // **Validates: Requirements 5.3**
        //
        // Every detection returned by the parser must have confidence ≥ 0.05.

        for _ in 0..<iterations {
            let numDetections = 300
            var data: [Float] = []

            for _ in 0..<numDetections {
                let x1 = Float.random(in: 0...640)
                let y1 = Float.random(in: 0...640)
                let x2 = Float.random(in: 0...640)
                let y2 = Float.random(in: 0...640)
                let confidence = Float.random(in: 0...1)
                let classId = Float(Int.random(in: 0...7))

                data.append(contentsOf: [x1, y1, x2, y2, confidence, classId])
            }

            let result = AcneDetectionService.parseRawDetections(
                from: data,
                numDetections: numDetections
            )

            for detection in result {
                #expect(
                    detection.confidence >= Double(confidenceThreshold),
                    "Detection with confidence \(detection.confidence) should not pass threshold \(confidenceThreshold)"
                )
            }
        }
    }

    @Test("Property 4b: All returned detections have valid class_id (acneType is not unknown)")
    func yoloParsing_allReturnedHaveValidClassId() {
        // **Validates: Requirements 5.4**
        //
        // Every detection returned by the parser must map to a known AcneType (not .unknown),
        // which means class_id was in [0, 5].

        for _ in 0..<iterations {
            let numDetections = 300
            var data: [Float] = []

            for _ in 0..<numDetections {
                let x1 = Float.random(in: 0...640)
                let y1 = Float.random(in: 0...640)
                let x2 = Float.random(in: 0...640)
                let y2 = Float.random(in: 0...640)
                let confidence = Float.random(in: 0...1)
                let classId = Float(Int.random(in: 0...7))

                data.append(contentsOf: [x1, y1, x2, y2, confidence, classId])
            }

            let result = AcneDetectionService.parseRawDetections(
                from: data,
                numDetections: numDetections
            )

            for detection in result {
                #expect(
                    detection.acneType != .unknown,
                    "Parser returned detection with .unknown acneType — class_id was not in [0, 5]"
                )
            }
        }
    }

    @Test("Property 4c: Detections below confidence threshold are never returned")
    func yoloParsing_lowConfidenceFiltered() {
        // **Validates: Requirements 5.3**
        //
        // If all detections in the input have confidence < 0.05, the parser SHALL
        // return an empty array.

        for _ in 0..<iterations {
            let numDetections = 300
            var data: [Float] = []

            for _ in 0..<numDetections {
                let x1 = Float.random(in: 0...640)
                let y1 = Float.random(in: 0...640)
                let x2 = Float.random(in: 0...640)
                let y2 = Float.random(in: 0...640)
                // All below threshold
                let confidence = Float.random(in: 0..<0.05)
                let classId = Float(Int.random(in: 0...5))

                data.append(contentsOf: [x1, y1, x2, y2, confidence, classId])
            }

            let result = AcneDetectionService.parseRawDetections(
                from: data,
                numDetections: numDetections
            )

            #expect(
                result.isEmpty,
                "Parser should return empty when all confidences are below threshold, got \(result.count) detections"
            )
        }
    }

    @Test("Property 4d: Detections with class_id > 5 are never returned")
    func yoloParsing_invalidClassIdFiltered() {
        // **Validates: Requirements 5.4**
        //
        // If all detections have class_id > 5 (outside [0, 5]), the parser SHALL
        // return empty regardless of confidence.

        for _ in 0..<iterations {
            let numDetections = 300
            var data: [Float] = []

            for _ in 0..<numDetections {
                let x1 = Float.random(in: 0...640)
                let y1 = Float.random(in: 0...640)
                let x2 = Float.random(in: 0...640)
                let y2 = Float.random(in: 0...640)
                let confidence = Float.random(in: 0.05...1.0) // All above threshold
                let classId = Float(Int.random(in: 6...7)) // All invalid class_ids

                data.append(contentsOf: [x1, y1, x2, y2, confidence, classId])
            }

            let result = AcneDetectionService.parseRawDetections(
                from: data,
                numDetections: numDetections
            )

            #expect(
                result.isEmpty,
                "Parser should return empty when all class_ids are > 5, got \(result.count) detections"
            )
        }
    }

    // MARK: - Edge Cases

    @Test("Edge case: confidence exactly at threshold (0.05) passes filter")
    func yoloParsing_exactThreshold() {
        // **Validates: Requirements 5.3**
        // Confidence of exactly 0.05 should be included (≥ check).
        let data: [Float] = [100, 100, 200, 200, 0.05, 0]
        let result = AcneDetectionService.parseRawDetections(from: data, numDetections: 1)
        #expect(result.count == 1)
    }

    @Test("Edge case: confidence just below threshold (0.0499) is excluded")
    func yoloParsing_justBelowThreshold() {
        // **Validates: Requirements 5.3**
        let data: [Float] = [100, 100, 200, 200, 0.0499, 0]
        let result = AcneDetectionService.parseRawDetections(from: data, numDetections: 1)
        #expect(result.isEmpty)
    }

    @Test("Edge case: class_id 5 (whitehead) is included")
    func yoloParsing_classId5Included() {
        // **Validates: Requirements 5.4**
        let data: [Float] = [100, 100, 200, 200, 0.9, 5]
        let result = AcneDetectionService.parseRawDetections(from: data, numDetections: 1)
        #expect(result.count == 1)
        #expect(result.first?.acneType == .whitehead)
    }

    @Test("Edge case: class_id 6 is excluded")
    func yoloParsing_classId6Excluded() {
        // **Validates: Requirements 5.4**
        let data: [Float] = [100, 100, 200, 200, 0.9, 6]
        let result = AcneDetectionService.parseRawDetections(from: data, numDetections: 1)
        #expect(result.isEmpty)
    }

    @Test("Edge case: empty data returns empty result")
    func yoloParsing_emptyData() {
        // **Validates: Requirements 5.3, 5.4**
        let result = AcneDetectionService.parseRawDetections(from: [], numDetections: 0)
        #expect(result.isEmpty)
    }

    @Test("Edge case: all detections pass both filters")
    func yoloParsing_allPass() {
        // **Validates: Requirements 5.3, 5.4**
        let numDetections = 50
        var data: [Float] = []
        for _ in 0..<numDetections {
            let x1 = Float.random(in: 0...320)
            let y1 = Float.random(in: 0...320)
            let x2 = Float.random(in: 320...640)
            let y2 = Float.random(in: 320...640)
            let confidence = Float.random(in: 0.05...1.0)
            let classId = Float(Int.random(in: 0...5))
            data.append(contentsOf: [x1, y1, x2, y2, confidence, classId])
        }

        let result = AcneDetectionService.parseRawDetections(from: data, numDetections: numDetections)
        #expect(result.count == numDetections)
    }

    @Test("Edge case: bounding box coordinates are correctly preserved in output")
    func yoloParsing_coordinateExtraction() {
        // **Validates: Requirements 5.3**
        // Verify that the parser extracts coordinates and normalizes them correctly.
        let x1: Float = 100
        let y1: Float = 150
        let x2: Float = 300
        let y2: Float = 350

        let data: [Float] = [x1, y1, x2, y2, 0.9, 2] // class 2 = nodule
        let result = AcneDetectionService.parseRawDetections(from: data, numDetections: 1)

        #expect(result.count == 1)
        guard let detection = result.first else { return }

        // The midpoint should be ((100+300)/2)/640, ((150+350)/2)/640 = 200/640, 250/640
        let expectedMidX = CGFloat(200.0 / 640.0)
        let expectedMidY = CGFloat(250.0 / 640.0)

        let bbox = detection.normalizedBoundingBox
        let actualMidX = bbox.midX
        let actualMidY = bbox.midY

        let tolerance: CGFloat = 0.001
        #expect(abs(actualMidX - expectedMidX) < tolerance,
                "midX mismatch: got \(actualMidX), expected \(expectedMidX)")
        #expect(abs(actualMidY - expectedMidY) < tolerance,
                "midY mismatch: got \(actualMidY), expected \(expectedMidY)")
    }
}
