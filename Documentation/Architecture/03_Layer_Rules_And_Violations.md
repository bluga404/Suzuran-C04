# Layer Rules and Violations

## Allowed Dependencies

- `App` -> `Core`, `Features`, `Infrastructure`
- `Presentation` -> `Domain`, `Core`
- `Data` -> `Domain`, `Core`, `Infrastructure`
- `Domain` -> `Core` only
- `Core` -> Foundation-level libraries only

## Disallowed Dependencies

- `Domain` importing `SwiftUI`.
- `Domain` depending on concrete repositories or network clients.
- `Presentation` directly decoding DTOs.
- `View` calling URLSession, UserDefaults, or persistence APIs.

## Typical Violations and Fixes

1. Violation: ViewModel creates URLSession request.
   Fix: define repository protocol in Domain, move implementation to Data.

2. Violation: DTO used directly in View.
   Fix: map DTO -> Domain Entity -> Presentation Model.

3. Violation: feature-specific colors/fonts hardcoded in each view.
   Fix: use Core DesignSystem tokens/components.

4. Violation: global singleton dependencies in feature code.
   Fix: inject dependencies via feature factory or app container.

5. Violation: root view manually waits 2 seconds to simulate splash.
   Fix: use system launch screen only; app opens immediately to first screen.

## File Placement Rules

- UseCases belong in `Domain/UseCases` and are implemented as concrete feature-domain types (no shared Core `UseCase` base protocol).
- Repository protocols belong in `Domain/Repositories`.
- Repository implementations belong in `Data/Repositories`.
- API DTOs belong in `Data/DTOs`.
- Mapping between layers belongs in `Data/Mappers` or `Presentation/Mapping`.
- Feature-specific view state belongs in `Presentation/Models`.

## Import Discipline

- Prefer `Foundation` in Domain and Data.
- Limit `SwiftUI` imports to Presentation and App layers.
- Limit `UIKit` usage to launch storyboard or adapters that cannot be expressed in SwiftUI.
