# Feature Implementation Checklist

Use this checklist whenever creating a new feature.

## 1. Feature Skeleton

- Create `Features/<FeatureName>/Domain`.
- Create `Features/<FeatureName>/Data`.
- Create `Features/<FeatureName>/Presentation`.
- Create `Features/<FeatureName>/Composition`.

## 2. Domain Layer

- Add entities for business meaning.
- Add repository protocol(s) for data contracts.
- Add concrete use case(s) for business actions in `Domain/UseCases` (without shared Core base protocol).
- Add domain-specific errors.

## 3. Data Layer

- Add DTOs for API/persistence boundaries.
- Add data sources (remote/local) behind protocols.
- Add mappers DTO <-> Domain.
- Add repository implementation conforming to domain protocol.

## 4. Presentation Layer

- Add ViewState enum or state model.
- Add ViewModel with `@Published` state transitions.
- Add SwiftUI views that render only from state.
- Add presentation mappers (domain to display model).

## 5. Composition Layer

- Create feature factory to wire dependencies.
- Keep object construction out of View and ViewModel where possible.

## 6. Base States

At minimum, handle:

- idle
- loading
- success
- empty
- error
- offline or permission-denied where relevant

## 7. Testing Scope (recommended)

- UseCase tests (business rules).
- Repository tests (mapping and fallback logic).
- ViewModel tests (state transitions).

## 8. Review Gate

- Confirm no forbidden dependency direction.
- Confirm naming convention compliance.
- Confirm feature docs are added in `Documentation/`.
