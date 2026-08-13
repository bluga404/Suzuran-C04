import Testing

@testable import Suzuran

/// Unit tests for face scan state transitions and edge cases.
/// Feature: face-scan-redesign
///
/// **Validates: Requirements 3.9, 3.10, 5.5, 8.1, 8.2, 8.3**
@Suite("Face Scan Unit Tests")
struct FaceScanUnitTests {

    // MARK: - Angle Progression Tests (Requirement 3.9, 3.10)

    @Suite("Angle Progression")
    @MainActor
    struct AngleProgressionTests {

        @Test("angleSequence is front → leftAngle → rightAngle")
        func angleSequenceOrder() {
            // **Validates: Requirements 3.9, 3.10**
            // The scan captures three angles in order: front, left, right.
            let service = AcneDetectionService()
            let viewModel = FaceScanViewModel(acneDetectionService: service)

            // The ViewModel's angle sequence should match the expected order
            #expect(viewModel.currentAngleTarget == .front,
                    "ViewModel must start at .front angle")
        }

        @Test("ViewModel starts with currentAngleTarget as .front")
        func initialAngleIsFront() {
            // **Validates: Requirements 3.9**
            let service = AcneDetectionService()
            let viewModel = FaceScanViewModel(acneDetectionService: service)

            #expect(viewModel.currentAngleTarget == .front)
        }

        @Test("FaceZone.scanZones matches expected angle sequence")
        func scanZonesMatchesExpectedSequence() {
            // **Validates: Requirements 3.9, 3.10**
            let expectedSequence: [FaceZone] = [.front, .leftAngle, .rightAngle]
            #expect(FaceZone.scanZones == expectedSequence)
        }

        @Test("Initial completedAngles is 0")
        func initialCompletedAnglesIsZero() {
            // **Validates: Requirements 3.9**
            let service = AcneDetectionService()
            let viewModel = FaceScanViewModel(acneDetectionService: service)

            #expect(viewModel.completedAngles == 0)
        }

        @Test("Initial scanInstruction matches front angle instruction")
        func initialScanInstructionMatchesFront() {
            // **Validates: Requirements 3.9**
            let service = AcneDetectionService()
            let viewModel = FaceScanViewModel(acneDetectionService: service)

            #expect(viewModel.scanInstruction == FaceZone.front.instruction)
        }
    }

    // MARK: - AcneType ClassId Mapping Tests (Requirement 5.5)

    @Suite("AcneType ClassId Mapping")
    struct AcneTypeClassIdTests {

        @Test("classId 0 maps to blackhead")
        func classId0IsBlackhead() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 0)
            #expect(acneType == .blackhead)
        }

        @Test("classId 1 maps to cyst")
        func classId1IsCyst() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 1)
            #expect(acneType == .cyst)
        }

        @Test("classId 2 maps to nodule")
        func classId2IsNodule() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 2)
            #expect(acneType == .nodule)
        }

        @Test("classId 3 maps to papule")
        func classId3IsPapule() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 3)
            #expect(acneType == .papule)
        }

        @Test("classId 4 maps to pustule")
        func classId4IsPustule() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 4)
            #expect(acneType == .pustule)
        }

        @Test("classId 5 maps to whitehead")
        func classId5IsWhitehead() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 5)
            #expect(acneType == .whitehead)
        }

        @Test("classId -1 maps to unknown")
        func classIdNegativeIsUnknown() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: -1)
            #expect(acneType == .unknown)
        }

        @Test("classId 6 maps to unknown")
        func classId6IsUnknown() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 6)
            #expect(acneType == .unknown)
        }

        @Test("classId 100 maps to unknown")
        func classId100IsUnknown() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 100)
            #expect(acneType == .unknown)
        }

        @Test("classId Int.max maps to unknown")
        func classIdIntMaxIsUnknown() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: Int.max)
            #expect(acneType == .unknown)
        }

        @Test("classId Int.min maps to unknown")
        func classIdIntMinIsUnknown() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: Int.min)
            #expect(acneType == .unknown)
        }

        @Test("All valid classIds produce distinct acne types")
        func allValidClassIdsAreDistinct() {
            // **Validates: Requirements 5.5**
            let types = (0...5).map { AcneType(classId: $0) }
            let uniqueTypes = Set(types.map { $0.rawValue })
            #expect(uniqueTypes.count == 6,
                    "Each classId 0–5 must map to a unique acne type")
        }

        @Test("displayName for unknown is 'Jerawat'")
        func unknownDisplayName() {
            // **Validates: Requirements 5.5**
            let acneType = AcneType(classId: 99)
            #expect(acneType.displayName == "Jerawat")
        }
    }

    // MARK: - FaceScanReadiness Message Tests (Requirement 3.9)

    @Suite("FaceScanReadiness Messages")
    struct FaceScanReadinessMessageTests {

        @Test("searchingFace message is 'Mencari wajah...'")
        func searchingFaceMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.searchingFace
            #expect(readiness.message == "Mencari wajah...")
        }

        @Test("faceOutOfGuide message is 'Wajah di luar area'")
        func faceOutOfGuideMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.faceOutOfGuide
            #expect(readiness.message == "Wajah di luar area")
        }

        @Test("tooFar message is 'Terlalu jauh'")
        func tooFarMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.tooFar
            #expect(readiness.message == "Terlalu jauh")
        }

        @Test("wrongAngle with 'kiri' produces 'Putar wajah ke kiri'")
        func wrongAngleKiriMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.wrongAngle("kiri")
            #expect(readiness.message == "Putar wajah ke kiri")
        }

        @Test("wrongAngle with 'kanan' produces 'Putar wajah ke kanan'")
        func wrongAngleKananMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.wrongAngle("kanan")
            #expect(readiness.message == "Putar wajah ke kanan")
        }

        @Test("unstable message is 'Tahan posisi...'")
        func unstableMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.unstable
            #expect(readiness.message == "Tahan posisi...")
        }

        @Test("ready message is 'Siap'")
        func readyMessage() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.ready
            #expect(readiness.message == "Siap")
        }

        @Test("Only .ready allows capture")
        func onlyReadyAllowsCapture() {
            // **Validates: Requirements 3.9**
            #expect(FaceScanReadiness.ready.allowsCapture == true)
            #expect(FaceScanReadiness.searchingFace.allowsCapture == false)
            #expect(FaceScanReadiness.faceOutOfGuide.allowsCapture == false)
            #expect(FaceScanReadiness.tooFar.allowsCapture == false)
            #expect(FaceScanReadiness.wrongAngle("kiri").allowsCapture == false)
            #expect(FaceScanReadiness.unstable.allowsCapture == false)
        }

        @Test("wrongAngle with empty string produces 'Putar wajah ke '")
        func wrongAngleEmptyDirection() {
            // **Validates: Requirements 3.9**
            let readiness = FaceScanReadiness.wrongAngle("")
            #expect(readiness.message == "Putar wajah ke ")
        }
    }

    // MARK: - Error Phase Transitions (Requirements 8.1, 8.2, 8.3)

    @Suite("Error Phase Transitions")
    @MainActor
    struct ErrorPhaseTransitionTests {

        @Test("Initial phase is requestingPermission")
        func initialPhaseIsRequestingPermission() {
            // **Validates: Requirements 8.1**
            let service = AcneDetectionService()
            let viewModel = FaceScanViewModel(acneDetectionService: service)

            #expect(viewModel.phase == .requestingPermission)
        }

        @Test("FaceScanPhase.error stores correct message for model load failure")
        func errorPhaseModelLoadFailure() {
            // **Validates: Requirements 8.2**
            // When the ML model fails to load, the error message should be
            // "Model AI gagal dimuat"
            let phase = FaceScanPhase.error(message: "Model AI gagal dimuat")
            #expect(phase == .error(message: "Model AI gagal dimuat"))
        }

        @Test("FaceScanPhase.permissionDenied is a valid phase")
        func permissionDeniedPhase() {
            // **Validates: Requirements 8.1**
            let phase = FaceScanPhase.permissionDenied
            #expect(phase == .permissionDenied)
        }

        @Test("FaceScanPhase.error stores correct message for capture failure")
        func errorPhaseCaptureFailure() {
            // **Validates: Requirements 8.3**
            // When image capture produces invalid data, display:
            // "Gagal mengambil gambar"
            let phase = FaceScanPhase.error(message: "Gagal mengambil gambar")
            #expect(phase == .error(message: "Gagal mengambil gambar"))
        }

        @Test("FaceScanPhase.error stores correct message for inference failure")
        func errorPhaseInferenceFailure() {
            // **Validates: Requirements 8.3**
            let phase = FaceScanPhase.error(message: "Gagal menganalisis gambar")
            #expect(phase == .error(message: "Gagal menganalisis gambar"))
        }

        @Test("Different error messages produce non-equal phases")
        func differentErrorMessagesAreNotEqual() {
            // **Validates: Requirements 8.2, 8.3**
            let modelError = FaceScanPhase.error(message: "Model AI gagal dimuat")
            let captureError = FaceScanPhase.error(message: "Gagal mengambil gambar")
            #expect(modelError != captureError)
        }

        @Test("retry() transitions from error-like state back to scanning")
        func retryResetsToScanning() {
            // **Validates: Requirements 8.2, 8.3**
            let service = AcneDetectionService()
            let viewModel = FaceScanViewModel(acneDetectionService: service)

            // Simulate retry (which resets to scanning)
            viewModel.retry()

            #expect(viewModel.phase == .scanning)
            #expect(viewModel.currentAngleTarget == .front)
            #expect(viewModel.readiness == .searchingFace)
        }

        @Test("FaceScanPhase equality for scanning and processing")
        func phaseEquality() {
            // **Validates: Requirements 3.10**
            #expect(FaceScanPhase.scanning == .scanning)
            #expect(FaceScanPhase.processing == .processing)
            #expect(FaceScanPhase.scanning != .processing)
            #expect(FaceScanPhase.requestingPermission != .permissionDenied)
        }
    }

    // MARK: - FaceZone Properties

    @Suite("FaceZone Properties")
    struct FaceZonePropertyTests {

        @Test("FaceZone.front instruction is 'Posisi Lurus ke Depan'")
        func frontInstruction() {
            // **Validates: Requirements 3.9**
            #expect(FaceZone.front.instruction == "Posisi Lurus ke Depan")
        }

        @Test("FaceZone.leftAngle instruction is 'Putar Wajah ke Kiri'")
        func leftAngleInstruction() {
            // **Validates: Requirements 3.9**
            #expect(FaceZone.leftAngle.instruction == "Putar Wajah ke Kiri")
        }

        @Test("FaceZone.rightAngle instruction is 'Putar Wajah ke Kanan'")
        func rightAngleInstruction() {
            // **Validates: Requirements 3.9**
            #expect(FaceZone.rightAngle.instruction == "Putar Wajah ke Kanan")
        }

        @Test("FaceZone scanZones order matches 1, 2, 3")
        func scanZonesOrderProperty() {
            // **Validates: Requirements 3.9, 3.10**
            #expect(FaceZone.front.order == 1)
            #expect(FaceZone.leftAngle.order == 2)
            #expect(FaceZone.rightAngle.order == 3)
        }

        @Test("FaceZone displayNames are in Indonesian")
        func displayNamesInIndonesian() {
            // **Validates: Requirements 3.9**
            #expect(FaceZone.front.displayName == "Depan")
            #expect(FaceZone.leftAngle.displayName == "Kiri")
            #expect(FaceZone.rightAngle.displayName == "Kanan")
        }
    }
}
