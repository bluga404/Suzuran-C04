# Panduan Membuat Fitur Baru

## Langkah-langkah

### 1. Buat Folder Fitur

```
Suzuran/Features/[NamaFitur]/
├── [NamaFitur]Factory.swift
├── Models/
├── ViewModels/
│   └── [NamaFitur]ViewModel.swift
└── Views/
    ├── [NamaFitur]View.swift
    └── Components/
```

### 2. Buat Models

Definisikan data model yang dibutuhkan fitur ini.

```swift
// Features/Skincare/Models/SkincareProduct.swift
import Foundation

struct SkincareProduct: Identifiable, Equatable {
    let id: UUID
    let name: String
    let brand: String
    let ingredients: [String]
    
    init(id: UUID = UUID(), name: String, brand: String, ingredients: [String]) {
        self.id = id
        self.name = name
        self.brand = brand
        self.ingredients = ingredients
    }
}
```

### 3. Buat Service (Jika Diperlukan)

Hanya buat service jika ada logic kompleks yang terpisah dari UI.

```swift
// Features/Skincare/Services/SkincareService.swift
import Foundation

final class SkincareService {
    func fetchProducts() async throws -> [SkincareProduct] {
        // implementation
    }
}
```

### 4. Buat ViewModel

```swift
// Features/Skincare/ViewModels/SkincareViewModel.swift
import Combine
import SwiftUI

@MainActor
final class SkincareViewModel: ObservableObject {
    @Published private(set) var products: [SkincareProduct] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let service: SkincareService
    
    init(service: SkincareService) {
        self.service = service
    }
    
    func loadProducts() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                products = try await service.fetchProducts()
            } catch {
                errorMessage = "Gagal memuat produk skincare"
            }
        }
    }
}
```

### 5. Buat View

```swift
// Features/Skincare/Views/SkincareView.swift
import SwiftUI

struct SkincareView: View {
    @ObservedObject private var viewModel: SkincareViewModel
    let onDismiss: () -> Void
    
    init(viewModel: SkincareViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            List(viewModel.products) { product in
                Text(product.name)
            }
            .navigationTitle("Skincare")
            .onAppear { viewModel.loadProducts() }
        }
    }
}
```

### 6. Buat Factory

```swift
// Features/Skincare/SkincareFactory.swift
import SwiftUI

enum SkincareFactory {
    @MainActor
    static func makeView(onDismiss: @escaping () -> Void = {}) -> some View {
        let service = SkincareService()
        let viewModel = SkincareViewModel(service: service)
        return SkincareView(viewModel: viewModel, onDismiss: onDismiss)
    }
}
```

### 7. Tambahkan Route (Jika Navigasi dari Halaman Lain)

Tambahkan case baru di `App/Navigation/AppRoute.swift`:

```swift
enum AppRoute: Hashable {
    case home
    case faceScan
    case skincare    // ← tambah ini
}
```

### 8. Hubungkan dari Halaman Pemanggil

Dari HomeView atau halaman lain:

```swift
.fullScreenCover(isPresented: $isShowingSkincare) {
    SkincareFactory.makeView(onDismiss: {
        isShowingSkincare = false
    })
}
```

## Checklist Fitur Baru

- [ ] Folder fitur dibuat di `Features/[NamaFitur]/`
- [ ] Factory method tersedia
- [ ] ViewModel menggunakan `@MainActor` + `ObservableObject`
- [ ] View menerima ViewModel via init (bukan buat sendiri)
- [ ] Error ditampilkan dalam Bahasa Indonesia
- [ ] Menggunakan design tokens (AppSpacing, AppColor, AppTypography)
- [ ] Tidak ada kode yang duplikat dengan Core
- [ ] File header sesuai template
- [ ] Commit message sesuai Conventional Commits

## Yang TIDAK Boleh Dilakukan

- ❌ Membuat UseCase, Repository, DataSource, Mapper terpisah (kecuali benar-benar perlu)
- ❌ Membuat protocol untuk setiap service (hanya jika perlu mock untuk testing)
- ❌ Meletakkan UI string dalam Bahasa Inggris
- ❌ Hardcode warna, spacing, atau font size
- ❌ Import library third-party tanpa diskusi tim
- ❌ Commit langsung ke `main` atau `development`
