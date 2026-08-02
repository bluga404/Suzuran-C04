# Example Feature: Acne Detection (Reference Only)

## Intent

This feature is fully implemented for architecture learning and team reference.
It is intentionally not connected to main app navigation.

## Architecture Mapping

- Domain:
  - `AcneAnalysis` entity and related value types.
  - `AcneAnalysisRepository` protocol.
  - `AnalyzeAcneFromImageUseCase` and `GetAcneAnalysisHistoryUseCase`.
- Data:
  - remote data source protocol + mock implementation.
  - local data source protocol + in-memory implementation.
  - DTOs and mapper.
  - repository implementation.
- Presentation:
  - view state enum and card model.
  - mapper for display text.
  - view model for state transitions.
  - SwiftUI view rendering all states.
- Composition:
  - `ExampleFeatureFactory` wiring all dependencies.

## Supported States in Example ViewModel

- idle
- analyzing
- analysisResult
- history
- emptyHistory
- error

## End-to-End Flow

1. View triggers `analyzeSampleImage()`.
2. ViewModel sets `analyzing` state.
3. Concrete feature use case validates input and calls repository.
4. Repository calls remote data source and saves response to local data source.
5. Mapper converts DTO to domain entity.
6. ViewModel maps domain entity to presentation model.
7. View renders result card.

## Why This Matters

This demonstrates:

- strict layer boundaries,
- protocol-first dependencies,
- explicit mapping between technical and business models,
- reusable state rendering for production features.
