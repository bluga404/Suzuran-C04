# Apple HIG Checklist — iOS 26

Checklist ini wajib dipenuhi sebelum PR di-merge. Referensi lengkap: lihat `HIG_REFERENCE.md` di root project.

## Per-Screen Checklist

```
□ Dynamic Type: render dari xSmall sampai AX5 tanpa overlap
□ Dark Mode: semua warna adaptif (gunakan semantic colors)
□ VoiceOver: bisa navigasi tanpa melihat layar
□ Touch target: minimum 44×44pt untuk semua elemen interaktif
□ Text contrast: ≥ 4.5:1 untuk normal text, ≥ 3:1 untuk large text
□ Reduce Motion: animasi di-disable jika user setting aktif
□ Orientation: layout tidak rusak (atau landscape disabled)
```

## Typography Rules

| Gunakan | Jangan |
|---------|--------|
| `.font(AppTypography.body)` | `.font(.system(size: 16))` |
| Semantic text styles | Hardcode font size |
| `.monospacedDigit()` untuk angka berubah | Proportional spacing untuk timer/counter |

## Color Rules

| Gunakan | Jangan |
|---------|--------|
| `.foregroundStyle(.primary)` | `.foregroundColor(.black)` |
| `.foregroundStyle(.secondary)` | `.foregroundColor(.gray)` |
| `AppColor.accentPrimary` | Hardcode hex color inline |
| `Color(.systemBackground)` | `Color.white` |

## Navigation Rules (iOS 26)

| Gunakan | Jangan |
|---------|--------|
| `NavigationStack` | Custom navigation implementation |
| `.navigationTitle("Judul")` | Manual title view |
| `.toolbar { }` untuk actions | Custom floating buttons (kecuali memang floating) |
| System back button | Custom back button (kecuali ada alasan UX) |

## Liquid Glass Rules (iOS 26)

| Gunakan | Jangan |
|---------|--------|
| Biarkan system auto-apply glass | Manual `.glassEffect()` pada NavigationStack/List |
| `.buttonStyle(.glassProminent)` untuk primary floating action | Glass pada content rows |
| `.regularMaterial` untuk card backgrounds | `.background(.ultraThinMaterial).glassEffect()` (double glass) |
| Glass hanya di navigation/floating layer | Glass di content layer |

## Layout Rules

| Gunakan | Jangan |
|---------|--------|
| `AppSpacing` tokens | Hardcode `padding(16)` |
| `AppCornerRadius` tokens | Hardcode `cornerRadius(12)` |
| `.padding(AppSpacing.md)` | Magic numbers |
| 8-point grid | Arbitrary spacing |

## Button & Interaction

| Gunakan | Jangan |
|---------|--------|
| Standard `Button` + role | Custom tappable views tanpa accessibility |
| `.buttonStyle(.glassProminent)` untuk CTA | Custom button styling yang tidak accessible |
| Haptic feedback pada aksi penting | Haptic untuk setiap interaksi |
| Confirmation dialog untuk destructive | Langsung hapus tanpa konfirmasi |

## Image & Media

| Gunakan | Jangan |
|---------|--------|
| `.resizable().scaledToFit()` | Fixed frame tanpa aspect ratio |
| `@2x` dan `@3x` assets | Hanya 1x resolution |
| `.clipShape(RoundedRectangle(...))` | Manual masking yang tidak smooth |
| `.accessibilityLabel()` untuk informational images | Skip accessibility |

## SF Symbols

| Gunakan | Jangan |
|---------|--------|
| SF Symbols 7 icons | Custom icon sebelum cek SF Symbols |
| `.symbolRenderingMode(.hierarchical)` untuk depth | Random rendering mode |
| `.symbolEffect(.bounce)` untuk feedback | Custom animation yang tidak perlu |
| Match font size dengan adjacent text | Hardcode frame size |
