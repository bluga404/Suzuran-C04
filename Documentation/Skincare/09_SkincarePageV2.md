# 09 — Skincare Page V2

## Ringkasan

Dokumen ini merupakan pembaruan dari [09_SkincarePage.md](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Documentation/Skincare/09_SkincarePage.md) yang mencocokkan **requirements** yang sudah ditulis dengan **implementasi aktual** di codebase. Tujuannya adalah mengidentifikasi gap, menilai apa yang sudah optimal, dan menyusun improvement plan.

Referensi visual: SVG mockups di [Skincare_SVG/](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Documentation/Skincare/Skincare_SVG)

---

# 1. Ringkasan Audit: Requirements vs Implementasi

## Legenda Status

| Simbol | Arti |
|--------|------|
| ✅ | Sudah diimplementasikan dan sesuai requirements |
| ⚠️ | Sudah diimplementasikan tetapi **belum optimal / ada gap** |
| ❌ | Belum diimplementasikan |

---

## 1.1 Data Models

| # | Requirement (V1) | Status | File | Catatan |
|---|---|---|---|---|
| 5.1 | `AcneType` enum canonical | ✅ | [AcneType.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/FaceScan/Models/AcneType.swift) | Sudah ada di FaceScan module, dipakai oleh Skincare via `AcneProfileProvider` |
| 5.2 | `SkincareCategory` enum | ⚠️ | [AddSkincareViewModel.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/ViewModels/AddSkincareViewModel.swift) | **Gap:** Category disimpan sebagai `String`, bukan enum. Categories hanya hardcoded sebagai `[String]` array di ViewModel. Tidak ada mapping display name. |
| 5.3 | `IngredientReference` struct | ⚠️ | — | **Gap:** Tidak ada struct `IngredientReference` terpisah. Ingredient disimpan sebagai `[String]` mentah di `SkincareProduct`. Tidak ada canonical ID, `normalizedName`, atau `synonyms`. |
| 5.4 | `SkincareProduct` model | ⚠️ | [SkincareProduct.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Models/SkincareProduct.swift) | **Gap:** `ingredients` bertipe `[String]` bukan `[IngredientReference]`. Tidak ada `createdAt`/`updatedAt`. Punya field tambahan `brand` dan `isUsedCurrently` yang **tidak ada** di V1 spec. |
| 5.5 | `OCRIngredientResult` intermediate model | ⚠️ | — | **Gap:** Tidak ada model intermediate. OCR text langsung di-parse ke `[String]` dan disimpan ke `scannedIngredients`. Tidak ada `confidence` atau `rawText` yang disimpan. |
| 5.6 | `MatchedIngredient` struct | ⚠️ | [IngredientMatcher.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/IngredientMatcher.swift) | **Gap:** Implementasi menggunakan `MatchedRecommendation` yang menyimpan seluruh `SkincareIngredientRecommendation`, bukan hanya reference. Nama field berbeda dari spec. |
| 5.7 | `IngredientEvidence` struct | ❌ | — | Belum ada. Data evidence/source langsung ada di `SkincareIngredientRecommendation` (flat structure). |
| 6.1 | `SkincareDraft` model | ❌ | — | Tidak ada draft layer terpisah. `AddSkincareViewModel` langsung bertindak sebagai draft form. |
| 6.2 | Pending List | ❌ | — | Tidak ada `pendingSkincare` list. Skincare langsung di-save per produk (immediate save). |
| 6.3 | Save All flow | ❌ | — | Tidak ada batch save flow. |

---

## 1.2 Services & Repositories

| # | Requirement (V1) | Status | File | Catatan |
|---|---|---|---|---|
| 9 | `OCRService` protocol abstraction | ⚠️ | [IngredientOCRService.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/IngredientOCRService.swift) | **Gap:** Tidak ada protocol `OCRService`. Class langsung concrete tanpa abstraction. |
| 10 | Ingredient Extraction pipeline | ⚠️ | [IngredientParser.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/IngredientParser.swift) | **Gap:** Parser bekerja tapi tidak ada protocol `IngredientExtractionService`. Normalization ada (lowercase, trim) tetapi tidak melakukan canonical matching ke cosing setelah parse. Hasil OCR langsung menjadi raw string. |
| 14 | `SkincareRepository` abstraction | ✅ | [SkincareProductRepository.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/SkincareProductRepository.swift) | Ada protocol `SkincareProductRepositoryProtocol`. Implementasi menggunakan UserDefaults. |
| 26 | `IngredientRepository` | ⚠️ | [SkincareIngredientRepository.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/SkincareIngredientRepository.swift) | **Gap:** Tidak ada protocol. Class concrete. Menggabungkan `cosing` search dan `AcneIngredients` recommendation dalam satu class, melanggar separation of concerns. Cosing hanya menyimpan nama, bukan struct `IngredientReference`. |
| 26 | `AcneIngredientRepository` | ⚠️ | [SkincareIngredientRepository.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/SkincareIngredientRepository.swift) | **Gap:** Digabung dalam `SkincareIngredientRepository`, bukan terpisah. |
| 27 | `IngredientMatchingService` protocol | ⚠️ | [IngredientMatcher.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/IngredientMatcher.swift) | **Gap:** Tidak ada protocol. Static class tanpa dependency injection. Matching berdasarkan string comparison (display name), bukan canonical ID. |
| — | `AcneProfileProvider` | ⚠️ | [AcneProfileProvider.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Services/AcneProfileProvider.swift) | **Gap:** Ada protocol `AcneProfileProviding`. Implementasi masih **mock** (hardcoded return `[.whitehead, .blackhead, .pustule]`). Belum terintegrasi dengan Home/FaceScan. |

---

## 1.3 ViewModels

| # | Requirement (V1) | Status | File | Catatan |
|---|---|---|---|---|
| 15 | `SkincareViewModel` (parent) | ⚠️ | [SkincareViewModel.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/ViewModels/SkincareViewModel.swift) | **Gap:** Tidak ada `pendingSkincare`, `currentDraft`, atau `isLoading/errorMessage`. Match disimpan per product UUID. Matching selalu dihitung ulang di `loadData()`. Tidak ada async operations. |
| 16 | Separated ViewModels (`SkincareFormViewModel`, `IngredientScannerViewModel`, `IngredientMatchViewModel`) | ⚠️ | [AddSkincareViewModel.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/ViewModels/AddSkincareViewModel.swift) | **Gap:** Hanya ada 2 ViewModel. `AddSkincareViewModel` menggabungkan form + OCR logic. Tidak ada `IngredientMatchViewModel` terpisah. |

---

## 1.4 Views & Components

| # | Requirement (V1 / SVG) | Status | File | Catatan |
|---|---|---|---|---|
| 23.1 | `SkincareView` (entry point) | ✅ | [SkincareView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/SkincareView.swift) | Berfungsi dengan baik. Menampilkan empty state dan content. |
| 23.1 | `EmptySkincareView` | ⚠️ | [SkincareView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/SkincareView.swift) (inline) | **Gap:** Empty state bukan komponen terpisah, masih inline di `SkincareView`. Sesuai SVG `00_EmptyState.svg`. |
| 23.2 | `AddSkincareView` | ✅ | [AddSkincareView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/AddSkincareView.swift) | Sesuai SVG `01_AddSkincare.svg`. Form lengkap. |
| 23.2 | `CategorySelector` | ⚠️ | Inline di AddSkincareView | **Gap:** Picker biasa, bukan UI seperti di SVG `02_SelectCategory.svg` yang menampilkan icon/card selector. |
| 23.3 | `IngredientScannerView` | ✅ | [IngredientScanView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/IngredientScanView.swift) | Sesuai SVG `03_IngredientScanClick.svg`. |
| 23.3 | `ScanInstructionView` (info modal) | ❌ | — | SVG `03A_ScanInfo.svg` dan `03B_ScanInfoFullModal.svg` menunjukkan info sheet sebelum scan. Belum ada di codebase. |
| 23.3 | `IngredientReviewView` | ✅ | [IngredientReviewView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/IngredientReviewView.swift) | Sesuai SVG `04_TypingAddIngredientManuallyAfterScan.svg`. |
| 23.4 | `IngredientSearchView` | ✅ | [IngredientSearchView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/IngredientSearchView.swift) | Berfungsi baik. |
| 23.5 | `SkincareDetailView` | ✅ | [SkincareDetailView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/SkincareDetailView.swift) | Menampilkan detail produk, rekomendasi, dan komposisi. |
| 23.6 | `IngredientDetailView` | ✅ | [IngredientDetailView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/IngredientDetailView.swift) | Sesuai SVG `10_IngredientDetailPage.svg`. |
| — | `SkincareCard` | ✅ | [SkincareCard.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/Components/SkincareCard.swift) | Tampil baik. |
| — | `IngredientChip` | ✅ | [IngredientChip.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/Components/IngredientChip.swift) | Sesuai SVG `05_IngredientAdded.svg`. |
| — | `RecommendationCard` | ✅ | [RecommendationCard.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/Components/RecommendationCard.swift) | Sesuai SVG `09_SeeDetails.svg`. |
| — | `CameraPicker` | ✅ | [CameraPicker.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/Components/CameraPicker.swift) | UIKit bridge. |
| — | `EditSkincareView` | ✅ | [EditSkincareView.swift](file:///Users/walkervalentinuss/Documents/ADA/C04/Suzuran-C04/Suzuran/Features/Skincare/Views/EditSkincareView.swift) | Reuse AddSkincareView dengan `editingProduct`. |

---

## 1.5 State & Flow

| # | Requirement (V1) | Status | Catatan |
|---|---|---|---|
| 7.1 | Validation (category required, product name required) | ⚠️ | Validasi hanya cek `name` dan `brand` non-empty. **Category tidak divalidasi** (selalu default "Moisturizer"). |
| 13 | Clear All ingredients | ❌ | Belum ada tombol/fungsi "Clear All" untuk ingredient di draft. |
| 18 | Matching berdasarkan canonical ID | ⚠️ | **Matching berdasarkan string comparison** (`name.lowercased()`), bukan ID. Rentan mismatch. |
| 19 | Duplicate ingredient handling (unique across products) | ❌ | Duplikasi per-product sudah ada. **Cross-product duplicate** untuk matched ingredients belum ditangani. |
| 20 | Delete flow (confirmation, last product alert) | ⚠️ | Delete langsung tanpa confirmation dialog/alert. SVG `07A_DeleteSkincare.svg` menunjukkan ada alert. |
| 21 | Save Empty Skincare flow | ❌ | Tidak ada confirmation ketika save dengan data kosong. SVG `06A_SaveEmptySkincare.svg`. |
| 22 | Navigation hierarchy | ✅ | Menggunakan `NavigationStack` dengan proper hierarchy. |
| 29 | Error states (`SkincareError` enum) | ❌ | Tidak ada unified error enum. Error hanya ditangani ad-hoc. |
| 30 | Loading states (granular) | ⚠️ | Hanya `isProcessingOCR` yang ada. Tidak ada `isSearchingIngredient`, `isSaving`, `isMatching`. |
| 34 | State matrix | ⚠️ | State management cukup baik tapi beberapa state transisi belum lengkap. |

---

## 1.6 Skincare Home (SVG 08 — After Save)

Berdasarkan SVG `08_AfterSaveAllSkincareAndMatchedIngredients.svg`:

| Elemen | Status | Catatan |
|--------|--------|---------|
| Current Skincare section (list produk dengan icon, nama, brand) | ✅ | Ditampilkan melalui `SkincareCard` |
| "See Detail" per produk | ✅ | `NavigationLink` ke `SkincareDetailView` |
| "Matched Ingredient" section terpisah | ⚠️ | **Gap:** Matched ingredients ditampilkan **per produk** di `SkincareDetailView`, bukan sebagai section terpisah di home. SVG menunjukkan "Matched Ingredient" sebagai section tersendiri di Skincare Home. |
| Add button (+) di toolbar | ✅ | Ada di toolbar trailing. |
| Acne type badge per matched ingredient | ✅ | Ada di `RecommendationCard`. |

---

# 2. Prioritas Improvement

## 2.1 Critical (Arsitektur & Data Integrity)

### C1: Buat `IngredientReference` struct

**Saat ini:** Ingredients hanya `[String]`.

**Seharusnya:** `IngredientReference` dengan `id`, `name`, `normalizedName`. Ini adalah fondasi dari seluruh matching system.

**Impact:** Tanpa canonical ID, matching tidak reliable. String comparison rentan typo dan case mismatch.

---

### C2: Buat `SkincareCategory` enum

**Saat ini:** Category bertipe `String` dan hardcoded.

**Seharusnya:** Proper Swift enum dengan `displayName` computed property.

---

### C3: Protocol untuk semua services

**Saat ini:** `IngredientOCRService`, `SkincareIngredientRepository`, `IngredientMatcher` tidak memiliki protocol.

**Seharusnya:** Setiap service mempunyai protocol agar testable dan replaceable.

Protocols yang diperlukan:
```text
OCRService
IngredientExtractionService
IngredientRepository (cosing)
AcneIngredientRepository
IngredientMatchingService
```

---

### C4: Pisahkan `SkincareIngredientRepository`

**Saat ini:** Satu class menangani `cosing` search DAN `AcneIngredients` recommendation.

**Seharusnya:** Dua repository terpisah:
- `IngredientRepository` → search cosing
- `AcneIngredientRepository` → match acne types

---

### C5: Integrasikan `AcneProfileProvider` dengan Home/FaceScan

**Saat ini:** Mock data hardcoded.

**Seharusnya:** Mengambil data acne terakhir dari `ScanHistoryStore` atau service yang digunakan Home.

---

## 2.2 High (User Experience & SVG Compliance)

### H1: Tambahkan "Matched Ingredient" section di Skincare Home

SVG `08_AfterSaveAllSkincareAndMatchedIngredients.svg` menunjukkan bahwa setelah save, Skincare Home menampilkan:

```text
Current Skincare
├── Product 1
├── Product 2
└── See Detail →

Matched Ingredient
├── Ingredient 1 → [Acne Types]
├── Ingredient 2 → [Acne Types]
└── See Detail →
```

**Saat ini:** Matched ingredients hanya muncul di `SkincareDetailView` per produk.

**Seharusnya:** Section terpisah di home yang menampilkan **unique** matched ingredients dari **semua** produk.

---

### H2: Implementasi delete confirmation flow

SVG `07A_DeleteSkincare.svg` menunjukkan:
- Confirmation alert sebelum delete
- Khusus handling saat produk terakhir (Keep Empty / Cancel)

**Saat ini:** Delete langsung tanpa konfirmasi.

**Seharusnya:** Gunakan `SkincareAlert` enum:
```swift
enum SkincareAlert {
    case deleteProduct(SkincareProduct)
    case deleteLastProduct
    case saveEmpty
}
```

---

### H3: Tambahkan Scan Instruction View

SVG `03A_ScanInfo.svg` dan `03B_ScanInfoFullModal.svg` menunjukkan info screen/modal yang menjelaskan cara scan sebelum user memulai.

**Saat ini:** Tidak ada.

**Seharusnya:** Sheet/modal informatif yang muncul saat pertama kali scan atau via info button.

---

### H4: Perbaiki Category Selector UI

SVG `02_SelectCategory.svg` menunjukkan selector berupa card/chip dengan icon per category, bukan picker biasa.

**Saat ini:** Picker standar SwiftUI.

**Seharusnya:** Grid atau horizontal scroll dari category chips/cards dengan icon.

---

### H5: Extract EmptySkincareView sebagai komponen terpisah

**Saat ini:** Inline di `SkincareView`.

**Seharusnya:** File terpisah `EmptySkincareView.swift` untuk maintainability dan reusability.

---

## 2.3 Medium (Robustness & Quality)

### M1: Buat `OCRIngredientResult` intermediate model

**Saat ini:** OCR → raw text → langsung parse ke `[String]`.

**Seharusnya:** OCR → `OCRIngredientResult` → user review → canonical matching → save.

---

### M2: Implementasi Clear All untuk ingredients

**Saat ini:** User hanya bisa hapus satu per satu.

**Seharusnya:** Tombol "Clear All" yang reset seluruh ingredient list pada draft.

---

### M3: Buat unified `SkincareError` enum

```swift
enum SkincareError: LocalizedError {
    case ocrFailed
    case ingredientNotFound
    case databaseUnavailable
    case saveFailed
    case deleteFailed
    case matchingFailed
}
```

---

### M4: Granular loading states

**Saat ini:** Hanya `isProcessingOCR`.

**Seharusnya:** Loading state per operation:
```swift
@Published var isScanning = false
@Published var isSearchingIngredient = false
@Published var isSaving = false
@Published var isMatching = false
```

---

### M5: Matching berdasarkan canonical ID

**Saat ini:** `ingredient.name == acneIngredient.name` (string comparison, lowercase).

**Seharusnya:** `ingredient.id == acneIngredient.ingredientID`

Ini tergantung pada implementasi C1 (`IngredientReference`) terlebih dahulu.

---

## 2.4 Low (Nice to Have)

### L1: `SkincareDraft` model dan pending list

V1 spec mendeskripsikan two-layer save (draft → pending → persist). Implementasi saat ini lebih simpel (langsung save). Bisa dipertimbangkan jika UX memerlukan batch save.

---

### L2: `IngredientEvidence` model terpisah

**Saat ini:** Evidence data sudah tersedia di `SkincareIngredientRecommendation` (description, research papers, dll) sebagai flat structure.

**Seharusnya (ideal):** `IngredientEvidence` terpisah agar data referensi tidak bloat model utama.

**Catatan:** Ini lower priority karena current flat structure sudah berfungsi.

---

### L3: Cross-product duplicate handling

Ketika ingredient muncul di beberapa produk, matched section harus menampilkan unique ingredients saja.

---

### L4: `updatedAt` dan `createdAt` timestamps

Menambahkan timestamp ke `SkincareProduct` untuk tracking perubahan.

---

# 3. Hal yang Sudah Baik dan Tidak Perlu Diubah

| Area | Detail |
|------|--------|
| **Empty State UI** | Sesuai SVG `00_EmptyState.svg`. Header, icon, text, dan button sudah tepat. |
| **Add Skincare Form** | Form lengkap dengan informasi produk dan ingredient section. |
| **OCR Pipeline** | `IngredientOCRService` menggunakan Vision framework, accurate mode, bahasa Inggris. Berfungsi baik. |
| **Ingredient Parser** | Logika parsing ingredient dari raw OCR text sudah cukup robust (handle keyword start/stop, separator normalization). |
| **Ingredient Search** | Search cosing dengan prioritas recommendation ingredients. Duplicate prevention case-insensitive. |
| **Ingredient Chip Component** | Visual distinction antara matched dan non-matched ingredients. Delete button optional. |
| **Product Repository** | Protocol ada. CRUD operations lengkap via UserDefaults. |
| **Navigation Structure** | NavigationStack dengan proper hierarchy dan sheet presentations. |
| **Edit Skincare** | Reuse AddSkincareView dengan `editingProduct` — clean approach. |
| **Ingredient Detail View** | Menampilkan detail yang sesuai SVG `10_IngredientDetailPage.svg`. |
| **SkincareFactory** | Dependency injection via factory pattern. Clean DI setup. |

---

# 4. Perbedaan Desain antara V1 Spec dan Implementasi Aktual

Beberapa perbedaan yang **sengaja** atau **acceptable**:

| V1 Spec | Implementasi | Assessment |
|---------|-------------|------------|
| `SkincareProduct` tanpa `brand` dan `isUsedCurrently` | `SkincareProduct` punya `brand` dan `isUsedCurrently` | ✅ **Improvement**. Brand penting untuk user identification. `isUsedCurrently` memungkinkan tracking active/inactive. |
| Draft → Pending → Save All (3 layer) | Direct save per product | ✅ **Simpler**. UX lebih straightforward untuk MVP. Bisa ditambahkan nanti. |
| `SkincareIngredientRecommendation` model terpisah dari cosing | Sudah terpisah di JSON file | ✅ **Sesuai**. `AcneIngredients.json` dan `cosing.json` sudah terpisah. |
| `MatchedIngredient` struct minimal | `MatchedRecommendation` yang lebih kaya (simpan recommendation detail) | ✅ **Improvement**. Mengurangi fetch tambahan untuk menampilkan detail. |

---

# 5. Rekomendasi Urutan Pengerjaan Improvement

```text
Phase 1: Data Contract Improvement
─────────────────────────────────
C2 → SkincareCategory enum
C1 → IngredientReference struct
     (Update SkincareProduct.ingredients: [IngredientReference])
M1 → OCRIngredientResult model

Phase 2: Service Architecture
─────────────────────────────
C3 → Protocols untuk semua service
C4 → Pisahkan SkincareIngredientRepository
M5 → Matching berdasarkan canonical ID

Phase 3: User Experience
────────────────────────
H1 → Matched Ingredient section di Home
H2 → Delete confirmation flow
H3 → Scan Instruction View
H4 → Category Selector UI
H5 → Extract EmptySkincareView

Phase 4: Robustness
───────────────────
M2 → Clear All ingredients
M3 → SkincareError enum
M4 → Granular loading states
C5 → Integrasi AcneProfileProvider

Phase 5: Polish
──────────────
L1 → Draft & Pending list (optional)
L2 → IngredientEvidence model (optional)
L3 → Cross-product duplicate handling
L4 → Timestamps
```

---

# 6. Mapping SVG → Implementasi

| SVG File | Tampilan | Implemented? | File |
|----------|----------|:---:|------|
| `00_EmptyState.svg` | Empty state skincare | ✅ | SkincareView.swift (inline) |
| `01_AddSkincare.svg` | Form tambah skincare | ✅ | AddSkincareView.swift |
| `02_SelectCategory.svg` | Category selection cards | ⚠️ | Picker biasa, bukan card UI |
| `03_IngredientScanClick.svg` | Scan ingredient prompt | ✅ | IngredientScanView.swift |
| `03A_ScanInfo.svg` | Scan instruction info | ❌ | — |
| `03B_ScanInfoFullModal.svg` | Scan info full modal | ❌ | — |
| `04_TypingAddIngredientManuallyAfterScan.svg` | Review hasil scan + manual add | ✅ | IngredientReviewView.swift |
| `05_IngredientAdded.svg` | Ingredient chips added | ✅ | IngredientChip.swift + AddSkincareView |
| `06_SkincareAdded.svg` | Skincare added to list | ✅ | SkincareView.swift (content) |
| `06A_SaveEmptySkincare.svg` | Alert save empty skincare | ❌ | — |
| `07_ManySkincareAdded.svg` | Multiple skincare list | ✅ | SkincareView.swift |
| `07A_DeleteSkincare.svg` | Delete confirmation alert | ❌ | — |
| `08_AfterSaveAllSkincareAndMatchedIngredients.svg` | Home with matched ingredients | ⚠️ | Matched section di detail saja |
| `09_SeeDetails.svg` | Matched ingredient cards | ✅ | RecommendationCard.swift |
| `10_IngredientDetailPage.svg` | Detail ingredient page | ✅ | IngredientDetailView.swift |

---

# 7. Prinsip Arsitektur (Diperbaharui)

Mempertahankan 10 prinsip dari V1 dengan catatan status:

1. **`SkincareProduct` adalah user data.** ✅ Sudah sesuai.
2. **`cosing` adalah reference data untuk canonical ingredient.** ⚠️ Belum memakai canonical ID.
3. **`AcneIngredients` adalah reference data untuk matching.** ✅ Sudah sesuai.
4. **Acne condition berasal dari Home / Scan, bukan dihitung ulang di Skincare.** ⚠️ Masih mock.
5. **OCR hanya bertugas mengekstrak text; OCR bukan source of truth.** ✅ Sudah sesuai.
6. **Ingredient yang disimpan sebaiknya menggunakan canonical ID dari `cosing`.** ❌ Masih raw string.
7. **Draft form dipisahkan dari persisted skincare.** ⚠️ Secara teknis terpisah via ViewModel state, tapi tidak ada model `SkincareDraft` eksplisit.
8. **Matching algorithm dipisahkan dari SwiftUI View.** ✅ Ada di `IngredientMatcher`.
9. **Delete last product dan save-empty merupakan dua alert flow yang berbeda.** ❌ Belum diimplementasikan.
10. **Camera dan Gallery menggunakan OCR pipeline yang sama.** ✅ Sudah sesuai.
