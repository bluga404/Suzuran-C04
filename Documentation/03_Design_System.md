# Design System

## Overview

Suzuran menggunakan design system berbasis token yang konsisten di seluruh aplikasi. Semua nilai visual (warna, spacing, typography, corner radius) didefinisikan sebagai konstanta di `Core/DesignSystem/Tokens/`.

## Tokens

### Spacing (`AppSpacing`)

```swift
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16    // ← Default padding
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

Gunakan `AppSpacing` untuk semua padding dan gap. Jangan hardcode angka.

### Corner Radius (`AppCornerRadius`)

```swift
enum AppCornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12    // ← Cards, buttons
    static let lg: CGFloat = 16    // ← Large containers, modals
}
```

### Typography (`AppTypography`)

```swift
enum AppTypography {
    static let title = Font.custom("AvenirNext-DemiBold", size: 28)
    static let subtitle = Font.custom("AvenirNext-Regular", size: 18)
    static let body = Font.custom("AvenirNext-Regular", size: 16)
    static let bodyBold = Font.custom("AvenirNext-DemiBold", size: 16)
    static let caption = Font.custom("AvenirNext-Regular", size: 13)
}
```

### Colors (`AppColor`)

```swift
enum AppColor {
    static let textPrimary = Color(...)
    static let textSecondary = Color(...)
    static let accentPrimary = Color(...)    // ← Brand green
    static let accentDanger = Color(...)     // ← Errors, destructive
    static let borderSubtle = Color(...)
}
```

**Aturan warna:**
- Gunakan `.primary` dan `.secondary` dari SwiftUI untuk teks di atas material backgrounds
- Gunakan `AppColor` untuk elemen brand-specific
- Jangan hardcode `Color.black` atau `Color.white` — gunakan semantic colors

## Komponen Reusable

### AppCard

Card dengan border dan background standar. Digunakan di home screen.

```swift
AppCard {
    VStack { ... }
}
```

### GlassCard

Card dengan material background. Digunakan di result screens.

```swift
GlassCard {
    VStack { ... }
}
```

### PrimaryButton

Button utama dengan styling konsisten.

```swift
PrimaryButton(title: "Mulai Scan", action: { ... })
```

### State Views

Views untuk menampilkan state khusus:
- `LoadingStateView(title:subtitle:)` — Loading indicator
- `ErrorStateView(title:message:primaryActionTitle:onPrimaryAction:)` — Error state
- `EmptyStateView(title:message:...)` — Empty content
- `PermissionStateView(title:message:...)` — Permission denied

## iOS 26 & Liquid Glass

### Yang Otomatis

Komponen SwiftUI standar **otomatis** mendapat Liquid Glass saat build dengan iOS 26 SDK:
- `NavigationStack` navigation bar
- `TabView` tab bar
- `Sheet` presentation
- `.toolbar { }` items
- Standard `Button`, `Toggle`, `Picker`

### Yang Manual

Untuk custom floating elements, gunakan `.glassEffect()`:

```swift
// Floating action button
Button("Action") { }
    .padding()
    .glassEffect(.regular.interactive())

// Penting: .glassEffect() harus jadi modifier TERAKHIR
```

### Yang TIDAK Boleh

- Jangan gunakan `.glassEffect()` pada List rows atau form content
- Jangan override `toolbarBackground` — biarkan system handle
- Jangan campurkan `.background(.ultraThinMaterial)` dengan `.glassEffect()` — pilih salah satu
- Jangan gunakan glass di content layer — glass hanya untuk navigation/floating layer
