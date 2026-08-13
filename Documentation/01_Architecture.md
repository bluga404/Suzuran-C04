# Arsitektur Aplikasi Suzuran

## Ringkasan

Suzuran menggunakan arsitektur **MVVM + Feature-Based** dengan SwiftUI. Setiap fitur adalah folder mandiri yang berisi semua kode yang diperlukan — tidak ada layer abstraksi berlebihan seperti UseCase, Repository, atau DataSource.

| Item | Value |
|------|-------|
| Pattern | MVVM (Model-View-ViewModel) |
| Organisasi | Feature-based folders |
| UI Framework | SwiftUI |
| Target iOS | 26+ |
| Language | Swift 6.0+ |
| Design Language | iOS 26 Liquid Glass + HIG |

## Prinsip Utama

1. **Simpel lebih baik dari pintar** — Tulis kode yang mudah dibaca. Hindari abstraksi yang tidak perlu.
2. **Feature = folder mandiri** — Semua kode untuk satu fitur ada dalam satu folder.
3. **Tidak ada layer yang tidak perlu** — ViewModel langsung memanggil service. Tidak ada UseCase, Repository, atau Mapper terpisah kecuali benar-benar diperlukan.
4. **Shared code di Core** — Design system, error handling, dan utilities yang dipakai banyak fitur ada di `Core/`.

## Struktur Folder

```
Suzuran/
├── App/                          # App lifecycle, navigation, bootstrapping
│   ├── SuzuranApp.swift
│   ├── AppBootstrapper.swift
│   ├── AppContainer.swift
│   ├── AppEnvironment.swift
│   ├── Navigation/
│   │   ├── AppRoute.swift
│   │   └── AppRouter.swift
│   └── Root/
│       ├── RootView.swift
│       └── RootViewModel.swift
│
├── Core/                         # Shared code (design system, utilities)
│   ├── DesignSystem/
│   │   ├── Components/           # Reusable UI components
│   │   ├── Modifiers/            # Custom view modifiers
│   │   └── Tokens/               # Colors, spacing, typography, corner radius
│   ├── Error/                    # AppError enum + mapper
│   ├── Foundation/               # Constants, shared enums
│   ├── Logging/                  # Logger
│   └── State/                    # Generic state types
│
├── Features/                     # Feature modules (masing-masing mandiri)
│   ├── Home/
│   │   └── Presentation/
│   │       ├── HomeView.swift
│   │       └── HomeViewModel.swift
│   │
│   ├── FaceScan/
│   │   ├── FaceScanFactory.swift
│   │   ├── Models/
│   │   ├── Services/
│   │   ├── ViewModels/
│   │   └── Views/
│   │       └── Components/
│   │
│   ├── [FeatureBaru]/            # Template untuk fitur baru
│   │   ├── [Feature]Factory.swift
│   │   ├── Models/
│   │   ├── Services/  (jika ada)
│   │   ├── ViewModels/
│   │   └── Views/
│   │       └── Components/
│   └── ...
│
└── Infrastructure/               # External dependencies (ML models, persistence)
    ├── ML/
    │   └── v26_fp16.mlpackage
    └── Persistence/
        ├── KeyValueStore.swift
        └── UserDefaultsKeyValueStore.swift
```

## Alur Data

```
User Action → View → ViewModel → Service (jika ada) → ViewModel → View Update
```

Tidak ada layer tambahan. ViewModel langsung mengakses service atau data source yang dibutuhkan.

## Feature Module Template

Setiap fitur baru mengikuti struktur ini:

```
Features/[NamaFitur]/
├── [NamaFitur]Factory.swift      # Factory method untuk membuat view + dependencies
├── Models/                        # Data models, enums, structs
│   └── ...
├── Services/                      # Business logic services (opsional)
│   └── ...
├── ViewModels/
│   └── [NamaFitur]ViewModel.swift
└── Views/
    ├── [NamaFitur]View.swift      # Main view
    └── Components/                 # Sub-views khusus fitur ini
        └── ...
```

## Factory Pattern

Setiap fitur memiliki factory yang:
- Membuat semua dependency yang dibutuhkan
- Mengembalikan view yang siap digunakan
- Dipanggil dari navigation layer

```swift
enum SkincareFiturFactory {
    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let service = SkincareService()
        let viewModel = SkincareViewModel(service: service)
        return SkincareView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
```

## Navigasi

Navigasi menggunakan `AppRouter` dengan `NavigationStack`:
- `AppRoute` enum mendefinisikan semua route yang tersedia
- Route baru ditambahkan sebagai case baru di `AppRoute`
- Factory dipanggil dari view yang menampilkan fitur (biasanya via `.fullScreenCover` atau `NavigationLink`)
