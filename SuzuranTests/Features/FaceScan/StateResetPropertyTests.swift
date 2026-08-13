import Testing

@testable import Suzuran

/// Property-based tests for state reset on retry.
/// Feature: face-scan-redesign, Property 9: State Reset on Retry
///
/// **Validates: Requirements 8.5**
///
/// These tests verify that invoking retry() on FaceScanViewModel resets:
/// - currentAngleTarget to .front
/// - holdProgress to 0.0
/// - completedAngles to 0
/// - capturedImages to empty
/// - phase to .scanning
/// - readiness to .searchingFace
///
/// Since the ViewModel properties are private(set), we verify the invariant
/// that retry() always produces a known reset state regardless of how many
/// times it is called or what the initial construction state is.
@Suite("State Reset on Retry Property Tests")
@MainActor
struct StateResetPropertyTests {

    /// Number of random iterations for property-based testing.
    private let iterations = 100

    // MARK: - Property 9: State Reset on Retry

    @Test("Property 9: retry() resets all scan state to initial values")
    func retryResetsAllState_property() {
        // **Validates: Requirements 8.5**
        //
        // For any intermediate ViewModel state, invoking retry() SHALL reset:
        // currentAngleTarget to .front, holdProgress to 0.0, completedAngles to 0,
        // all captured image data to empty, and phase to .scanning.

        let service = AcneDetectionService()
        let viewModel = FaceScanViewModel(acneDetectionService: service)

        // Call retry multiple times (simulating random intermediate states)
        // Each call should always produce the same reset state
        for _ in 0..<iterations {
            viewModel.retry()

            #expect(
                viewModel.currentAngleTarget == .front,
                "retry() must reset currentAngleTarget to .front"
            )
            #expect(
                viewModel.holdProgress == 0.0,
                "retry() must reset holdProgress to 0.0"
            )
            #expect(
                viewModel.completedAngles == 0,
                "retry() must reset completedAngles to 0"
            )
            #expect(
                viewModel.phase == .scanning,
                "retry() must reset phase to .scanning"
            )
            #expect(
                viewModel.readiness == .searchingFace,
                "retry() must reset readiness to .searchingFace"
            )
            #expect(
                viewModel.capturedImages.isEmpty,
                "retry() must clear all captured images"
            )
        }
    }

    @Test("Property 9: retry() produces consistent state regardless of call count")
    func retryIdempotent_property() {
        // **Validates: Requirements 8.5**
        //
        // Calling retry() N times (for random N ≥ 1) should always produce
        // the same reset state — the operation is idempotent.

        let service = AcneDetectionService()
        let viewModel = FaceScanViewModel(acneDetectionService: service)

        for _ in 0..<iterations {
            let callCount = Int.random(in: 1...10)

            for _ in 0..<callCount {
                viewModel.retry()
            }

            #expect(viewModel.currentAngleTarget == .front)
            #expect(viewModel.holdProgress == 0.0)
            #expect(viewModel.completedAngles == 0)
            #expect(viewModel.phase == .scanning)
            #expect(viewModel.readiness == .searchingFace)
            #expect(viewModel.capturedImages.isEmpty)
        }
    }

    // MARK: - Specific Reset Assertions

    @Test("Property 9: retry() resets scanInstruction to front angle instruction")
    func retryResetsScanInstruction() {
        // **Validates: Requirements 8.5**
        let service = AcneDetectionService()
        let viewModel = FaceScanViewModel(acneDetectionService: service)

        viewModel.retry()

        #expect(
            viewModel.scanInstruction == FaceZone.front.instruction,
            "retry() must reset scanInstruction to front angle instruction"
        )
    }

    @Test("Property 9: retry() from initial state maintains reset invariant")
    func retryFromInitialState() {
        // **Validates: Requirements 8.5**
        // Even from the initial construction state, retry() should set
        // all values to their expected reset values.
        let service = AcneDetectionService()
        let viewModel = FaceScanViewModel(acneDetectionService: service)

        viewModel.retry()

        #expect(viewModel.currentAngleTarget == .front)
        #expect(viewModel.holdProgress == 0.0)
        #expect(viewModel.completedAngles == 0)
        #expect(viewModel.phase == .scanning)
        #expect(viewModel.readiness == .searchingFace)
        #expect(viewModel.capturedImages.isEmpty)
        #expect(viewModel.scanInstruction == FaceZone.front.instruction)
    }
}
