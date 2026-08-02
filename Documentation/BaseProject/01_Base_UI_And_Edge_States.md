# Base UI and Edge States

## Base Design Tokens

Defined in `Core/DesignSystem/Tokens`:

- Color tokens (`AppColor`)
- Typography tokens (`AppTypography`)
- Spacing tokens (`AppSpacing`)
- Radius tokens (`AppCornerRadius`)

Purpose:

- Ensure consistent visual language.
- Avoid scattered hard-coded styling values.

## Base Components

Defined in `Core/DesignSystem/Components`:

- `PrimaryButton`: filled, bordered, destructive styles with loading support.
- `AppCard`: reusable elevated container.
- `AppTextField`: label + validation-aware text field.

## Base Edge-State Views

Defined in `Core/DesignSystem/Components/StateViews`:

- `LoadingStateView`
- `EmptyStateView`
- `ErrorStateView`
- `OfflineStateView`
- `PermissionStateView`

These components prevent each feature from rebuilding error/empty/loading UI differently.

## Screen Foundation

- `ScreenContainerModifier` applies app-wide background and full-screen layout behavior.

## UI State Management

- Shared generic state model: `LoadableState<Value>` in `Core/State`.
- Feature-specific state enums can still be used for richer flows.

## Consistency Rules

- Use tokens before creating custom values.
- If a visual pattern repeats more than once, convert it to component.
- Keep state-specific views explicit and reusable.
