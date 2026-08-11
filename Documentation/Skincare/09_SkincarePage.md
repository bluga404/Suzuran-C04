# 09 — Skincare Page

## 1. Tujuan Halaman

Skincare Page bertanggung jawab untuk:

1. Menyimpan skincare yang digunakan user.
2. Mengambil ingredient dari produk melalui OCR atau input manual.
3. Memvalidasi / mencocokkan ingredient terhadap database `cosing`.
4. Menghubungkan ingredient skincare dengan tipe jerawat user melalui database `AcneIngredients`.
5. Menampilkan insight ingredient yang relevan dengan kondisi jerawat user.
6. Menyediakan detail skincare dan detail ingredient.
7. Menangani seluruh state kosong, penambahan, penghapusan, dan penyimpanan skincare.

> **Catatan:** SVG yang diberikan digunakan sebagai source of truth untuk struktur UI dan state. Dokumen ini fokus pada kebutuhan **data, model, component/view, state management, dan algorithm/service boilerplate**, bukan mengubah desain UI.

---

# 2. State / Flow Utama

Flow halaman dapat dibagi menjadi beberapa state:

```text
Skincare Empty
    │
    └── Add Skincare Routine
            │
            ▼
        Add Skincare
            │
            ├── Select Category
            │
            ├── Product Name
            │
            └── Ingredients
                    │
                    ├── Camera
                    │      └── OCR
                    │
                    ├── Gallery
                    │      └── OCR
                    │
                    └── Manual Search
                           │
                           ▼
                    Ingredient List
                           │
                           └── Save Skincare
                                  │
                                  ▼
                         Skincare Draft/List
                                  │
                         ┌────────┴────────┐
                         │                 │
                  Add New Skincare      Save All
                         │                 │
                         ▼                 ▼
                  Add Skincare       Skincare Home
                                           │
                              ┌────────────┴─────────────┐
                              │                          │
                       Current Skincare          Match Ingredient
                              │                          │
                       See Detail                   See Detail
                              │                          │
                              ▼                          ▼
                       Skincare List             Ingredient List
                                                         │
                                                         ▼
                                                Ingredient Detail
```

---

# 3. Data Sources

Halaman ini membutuhkan minimal tiga sumber data utama.

## 3.1 User Skincare Data

Data yang dibuat dan dimiliki oleh user.

Contoh:

```swift
SkincareProduct
- id
- category
- productName
- ingredients
- createdAt
- updatedAt
```

## 3.2 `cosing`

Database referensi ingredient yang digunakan ketika:

- user menambahkan ingredient secara manual;
- OCR menghasilkan ingredient;
- ingredient hasil OCR perlu dinormalisasi;
- user melakukan search ingredient.

Minimal data yang perlu tersedia:

```text
id
name
normalizedName
synonyms
```

Jika dataset `cosing` memiliki field tambahan, field tersebut dapat dipertahankan tanpa harus langsung digunakan oleh UI.

### Fungsi utama

```text
User Input
    ↓
Normalize
    ↓
Search `cosing`
    ↓
Select Ingredient
    ↓
Store canonical ingredient
```

---

## 3.3 `AcneIngredients`

Database yang digunakan untuk menentukan ingredient yang relevan dengan tipe jerawat user.

Minimal struktur konseptual:

```text
Ingredient
    └── acneTypes[]
```

Contoh:

```json
{
  "ingredient": "Azelaic Acid",
  "acneTypes": [
    "Papules",
    "Whitehead"
  ]
}
```

Jika database memiliki informasi evidence / source, data tersebut juga dapat digunakan pada Ingredient Detail Page.

---

# 4. Hubungan Data dengan Home Page

Skincare Page tidak boleh membuat ulang data acne user.

`Home Page` menjadi sumber kondisi acne user.

Secara konseptual:

```text
Home / Scan Result
        │
        ▼
User Acne Condition
        │
        ├── Papules
        ├── Whitehead
        ├── Blackhead
        ├── Pustules
        └── Cysts
        │
        ▼
Skincare Page
        │
        ▼
AcneIngredients matching
        │
        ▼
Matched Ingredients
```

Jadi algorithm matching hanya menerima **acne type yang sudah dimiliki user**, bukan menghitung ulang acne dari halaman Skincare.

---

# 5. Data Model

## 5.1 AcneType

Gunakan satu enum / canonical representation untuk seluruh aplikasi.

```swift
enum AcneType: String, Codable, CaseIterable {
    case blackhead
    case whitehead
    case papule
    case pustule
    case cyst
}
```

> Nama dan casing final harus mengikuti canonical value yang sudah digunakan oleh Home / Scan model agar tidak terjadi mismatch.

---

## 5.2 SkincareCategory

Category yang tersedia dari UI:

```swift
enum SkincareCategory: String, Codable, CaseIterable {
    case cleanser
    case moisturizer
    case toner
    case serum
    case sunscreen
    case faceWash
    case spotTreatment
}
```

Perlu dibuat mapping antara enum internal dan display name.

Contoh:

```text
faceWash → "Facewash"
spotTreatment → "Spot Treatment"
```

---

## 5.3 IngredientReference

Representasi ingredient yang berasal dari `cosing`.

```swift
struct IngredientReference: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let normalizedName: String
    let synonyms: [String]
}
```

`normalizedName` penting untuk mencegah:

```text
Azelaic Acid
azelaic acid
AZELAIC ACID
```

dianggap sebagai tiga ingredient berbeda.

---

## 5.4 SkincareProduct

Model utama yang disimpan user.

```swift
struct SkincareProduct: Identifiable, Codable {
    let id: UUID
    var category: SkincareCategory
    var productName: String
    var ingredients: [IngredientReference]
    let createdAt: Date
    var updatedAt: Date
}
```

---

## 5.5 OCR Result

Jangan langsung memasukkan OCR output ke `SkincareProduct`.

Buat model intermediate:

```swift
struct OCRIngredientResult {
    let rawText: String
    let extractedIngredients: [String]
    let confidence: Double?
}
```

Tujuannya agar hasil OCR masih dapat diedit user sebelum disimpan.

Flow:

```text
Image
 ↓
OCR
 ↓
OCRIngredientResult
 ↓
Normalize
 ↓
Match/Search cosing
 ↓
User Confirmation
 ↓
SkincareProduct
```

---

## 5.6 Ingredient Match

Untuk hasil matching dengan kondisi acne:

```swift
struct MatchedIngredient: Identifiable {
    let id: String
    let ingredient: IngredientReference
    let matchedAcneTypes: [AcneType]
}
```

Contoh:

```text
Azelaic Acid
Matched:
- Papules
- Whitehead
```

---

## 5.7 Ingredient Detail

Ingredient Detail Page pada SVG menampilkan informasi seperti:

- ingredient name;
- publication date;
- summary / description;
- sources;
- expandable source content.

Karena detail ini terlihat berasal dari data referensi/evidence, sebaiknya jangan menyimpan seluruh informasi tersebut sebagai bagian dari `SkincareProduct`.

Pisahkan:

```text
User Data
    SkincareProduct

Reference Data
    IngredientReference
    IngredientEvidence / IngredientSource
```

Contoh konseptual:

```swift
struct IngredientEvidence {
    let id: String
    let ingredientID: String
    let publishedAt: Date?
    let summary: String
    let source: String
}
```

---

# 6. Draft vs Saved Data

Ini bagian penting untuk flow pada SVG.

Jangan langsung menyimpan data form ke permanent storage setiap kali user mengetik.

Gunakan dua layer:

```text
SkincareDraft
      ↓
Save Skincare
      ↓
Temporary / Pending Skincare List
      ↓
Save All Skincare
      ↓
Persisted Skincare
```

## 6.1 SkincareDraft

```swift
struct SkincareDraft: Identifiable {
    let id: UUID
    var category: SkincareCategory?
    var productName: String
    var ingredients: [IngredientReference]
}
```

Draft digunakan di Add Skincare.

## 6.2 Pending List

Ketika user menekan:

**Save Skincare**

draft diubah menjadi item yang masuk ke list skincare yang sedang disusun.

```swift
var pendingSkincare: [SkincareProduct]
```

Kemudian user dapat:

```text
Add New Skincare
        ↓
Draft baru
        ↓
Save Skincare
        ↓
pendingSkincare.append(...)
```

## 6.3 Save All

Ketika user menekan:

**Save All Skincare**

```text
pendingSkincare
        ↓
Persistence
        ↓
Saved skincare
        ↓
Home Skincare Content
```

---

# 7. Validation Rules

Validation perlu dibuat di layer ViewModel / Service, bukan tersebar di SwiftUI View.

## 7.1 Add Skincare

Minimal:

```text
Category       → required
Product Name   → required
Ingredients    → recommended / sesuai desain final
```

Jika desain mengizinkan save tanpa ingredient, state tersebut harus ditangani secara eksplisit.

SVG `06A_SaveEmptySkincare.svg` menunjukkan adanya confirmation ketika skincare kosong.

---

## 7.2 Product Name

Validasi dasar:

```text
trim whitespace
empty check
```

Tidak perlu membatasi nama berdasarkan database karena product name adalah free-form.

---

## 7.3 Ingredient

Ingredient sebaiknya disimpan sebagai canonical ingredient dari `cosing`.

Contoh:

```text
Input:
"azelaic acid"

Search:
cosing

Canonical:
"Azelaic Acid"
```

---

# 8. Ingredient OCR Pipeline

## 8.1 Camera / Gallery

Camera dan Gallery sebaiknya hanya bertanggung jawab menghasilkan:

```swift
UIImage
```

Kemudian image dikirim ke OCR service.

```text
Camera
   │
   ▼
Image
   │
   ▼
OCRService
```

Gallery memiliki pipeline yang sama:

```text
Gallery
   │
   ▼
Image
   │
   ▼
OCRService
```

Dengan demikian tidak perlu membuat dua implementation OCR.

---

# 9. OCR Service Boilerplate

Buat abstraction:

```swift
protocol OCRService {
    func recognizeText(from image: UIImage) async throws -> String
}
```

Kemudian:

```swift
final class IngredientOCRService: OCRService {
    func recognizeText(from image: UIImage) async throws -> String {
        // OCR implementation
    }
}
```

Service ini **tidak** bertanggung jawab menentukan apakah text tersebut valid sebagai ingredient.

---

# 10. Ingredient Extraction Algorithm

OCR menghasilkan raw text.

Contoh:

```text
Aqua, Glycerin, Niacinamide,
Azelaic Acid, Sodium Hyaluronate
```

Pipeline:

```text
Raw OCR Text
      ↓
Clean Text
      ↓
Split Ingredients
      ↓
Normalize
      ↓
Search cosing
      ↓
Canonical Ingredients
      ↓
Remove Duplicate
      ↓
Show User
```

---

## 10.1 Normalize

Contoh operasi:

```text
trim whitespace
lowercase
remove unnecessary punctuation
normalize repeated whitespace
```

Contoh:

```text
"  AZELAIC   ACID, "
        ↓
"azelaic acid"
```

---

## 10.2 Canonical Matching

Jangan menyimpan hasil OCR mentah sebagai final ingredient.

Gunakan:

```swift
func matchIngredient(
    _ rawIngredient: String,
    against database: [IngredientReference]
) -> IngredientReference?
```

Jika tidak ditemukan:

```text
Unknown Ingredient
```

dan user diberi kesempatan untuk search/manual add.

---

# 11. Manual Ingredient Search

Pada state setelah scan, user dapat mengetik ingredient.

Pipeline:

```text
Search Text
     ↓
Normalize
     ↓
Search cosing
     ↓
Search Result
     ↓
User Select
     ↓
Ingredient List
```

Gunakan search berdasarkan:

```text
name
normalizedName
synonyms
```

Jika database cukup besar, jangan load dan filter seluruh dataset secara manual di SwiftUI setiap keystroke.

Idealnya gunakan:

```text
IngredientRepository
        ↓
search(query:)
```

sehingga implementation storage dapat diganti kemudian.

---

# 12. Ingredient List State

Model state yang perlu diperhatikan:

```swift
enum IngredientInputState {
    case empty
    case scanning
    case scanResult
    case searching
    case populated
    case error
}
```

Namun jangan membuat terlalu banyak state jika tidak diperlukan.

Secara praktis, ViewModel dapat memiliki:

```swift
var ingredients: [IngredientReference]
var isScanning: Bool
var isSearching: Bool
var scanError: Error?
var searchQuery: String
```

---

# 13. Clear All

Flow dari SVG:

```text
Ingredient List
      ↓
Clear All
      ↓
Reset
      ↓
Scan Instruction / Initial Scan State
```

Clear All **tidak menghapus skincare product yang sudah tersimpan**.

Yang di-reset adalah ingredient input pada current draft.

```swift
func clearIngredients() {
    draft.ingredients.removeAll()
    resetScanState()
}
```

---

# 14. Skincare Repository

Buat abstraction persistence:

```swift
protocol SkincareRepository {
    func fetchAll() async throws -> [SkincareProduct]
    func save(_ skincare: SkincareProduct) async throws
    func saveAll(_ skincare: [SkincareProduct]) async throws
    func delete(_ skincare: SkincareProduct) async throws
}
```

Implementasi storage dapat menggunakan storage yang sudah digunakan project.

Yang penting View tidak mengetahui detail persistence.

---

# 15. Skincare ViewModel

Satu parent ViewModel dapat mengatur state utama.

Contoh boilerplate:

```swift
@MainActor
final class SkincareViewModel: ObservableObject {

    @Published var savedSkincare: [SkincareProduct] = []
    @Published var pendingSkincare: [SkincareProduct] = []

    @Published var currentDraft: SkincareDraft?

    @Published var matchedIngredients: [MatchedIngredient] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSkincare() async {}

    func startNewSkincare() {}

    func saveCurrentSkincare() {}

    func saveAllSkincare() async {}

    func deleteSkincare(_ skincare: SkincareProduct) async {}

    func calculateMatchedIngredients() async {}
}
```

---

# 16. Pisahkan ViewModel Berdasarkan Responsibility

Jika parent ViewModel menjadi terlalu besar, pecah menjadi:

```text
SkincareViewModel
    │
    ├── SkincareFormViewModel
    │
    ├── IngredientScannerViewModel
    │
    └── IngredientMatchViewModel
```

Recommended responsibility:

### `SkincareViewModel`

Mengatur:

- saved skincare;
- pending skincare;
- add;
- delete;
- save all;
- navigation state.

### `SkincareFormViewModel`

Mengatur:

- category;
- product name;
- ingredient input;
- validation;
- save current draft.

### `IngredientScannerViewModel`

Mengatur:

- camera;
- gallery;
- OCR;
- scan state;
- clear all;
- OCR error.

### `IngredientMatchViewModel`

Mengatur:

- acne type input;
- `AcneIngredients`;
- matching;
- matched ingredient list;
- ingredient detail.

---

# 17. Matching Algorithm

Input:

```text
User Acne Types
+
Saved Skincare Ingredients
+
AcneIngredients Database
```

Output:

```text
Matched Ingredients
```

Contoh:

```text
User acne:
[Papules, Whitehead]

Skincare:
[Niacinamide, Azelaic Acid, Glycerin]

Database:
Azelaic Acid → [Papules, Whitehead]
Niacinamide   → [Papules]
Glycerin      → [Other]
```

Output:

```text
Azelaic Acid
→ Papules
→ Whitehead

Niacinamide
→ Papules
```

Algorithm konseptual:

```swift
func matchIngredients(
    skincareIngredients: [IngredientReference],
    acneTypes: Set<AcneType>,
    database: AcneIngredientDatabase
) -> [MatchedIngredient]
```

---

# 18. Matching Harus Berdasarkan Canonical ID

Hindari:

```swift
ingredient.name == acneIngredient.name
```

Jika memungkinkan gunakan:

```swift
ingredient.id == acneIngredient.ingredientID
```

Karena:

```text
"Azelaic Acid"
"azelaic acid"
"AZELAIC ACID"
```

harus menunjuk ke entity yang sama.

---

# 19. Duplicate Handling

Jika ingredient terdapat di beberapa skincare:

```text
Cleanser
- Niacinamide

Serum
- Niacinamide
```

Match Ingredient section sebaiknya tidak menampilkan:

```text
Niacinamide
Niacinamide
```

dua kali.

Gunakan unique ingredient ID:

```swift
Set<IngredientReference.ID>
```

Kemudian tetap dapat menyimpan informasi produk mana saja yang mengandung ingredient tersebut jika dibutuhkan di tahap berikutnya.

---

# 20. Delete Flow

Ketika user menekan delete:

```text
Delete
 ↓
Confirmation Alert
 ↓
User decision
```

Jika jumlah skincare > 1:

```text
Delete
 ↓
Remove product
 ↓
Remain in skincare list
```

Jika jumlah skincare == 1:

```text
Delete
 ↓
Alert:
"Keep Empty"
"Cancel"
```

### Cancel

```text
No change
```

### Keep Empty

```text
Delete last skincare
        ↓
Empty state
```

Implementasi sebaiknya menggunakan satu function:

```swift
func requestDelete(_ skincare: SkincareProduct)
```

dan View hanya menentukan alert yang harus ditampilkan.

---

# 21. Save Empty Skincare Flow

SVG `06A_SaveEmptySkincare.svg` menunjukkan confirmation ketika data skincare kosong.

Flow:

```text
Save All Skincare
        ↓
savedSkincare.isEmpty
        ↓
Confirmation
        │
        ├── Cancel
        │     ↓
        │   Stay
        │
        └── Keep Empty
              ↓
          Empty State
```

Jangan mencampur kondisi ini dengan delete alert.

Buat state/action terpisah:

```swift
enum SkincareAlert {
    case saveEmpty
    case deleteProduct
    case deleteLastProduct
}
```

---

# 22. Navigation Structure

Recommended navigation hierarchy:

```text
TabBar
└── Skincare
    │
    ├── AddSkincareView
    │   ├── Category Selection
    │   ├── ScanInfo
    │   ├── IngredientScannerView
    │   └── Ingredient Search
    │
    ├── SkincareListView
    │
    ├── MatchIngredientView
    │
    └── IngredientDetailView
```

`SkincareView` menjadi entry point.

---

# 23. Component Breakdown

## Skincare Home

```text
SkincareView
├── EmptySkincareView
├── CurrentSkincareSection
│   ├── SkincareCard
│   └── SeeDetailButton
├── MatchIngredientSection
│   ├── MatchedIngredientCard
│   └── SeeDetailButton
└── AddNewSkincareButton
```

---

## Add Skincare

```text
AddSkincareView
├── ProductNameField
├── CategorySelector
├── IngredientSection
│   ├── ScanIngredientButton
│   ├── IngredientList
│   ├── IngredientSearchField
│   └── IngredientRow
└── SaveSkincareButton
```

---

## Scanner

```text
IngredientScannerView
├── CameraPreview
├── CaptureButton
├── GalleryPicker
├── ScanInstructionButton
└── ScanInstructionSheet
```

---

## Match Ingredient

```text
MatchIngredientView
├── AcneTypeContext
├── MatchedIngredientList
└── MatchedIngredientRow
```

---

## Ingredient Detail

```text
IngredientDetailView
├── IngredientHeader
├── EvidenceList
├── EvidenceCard
└── SourcesSection
```

---

# 24. Data Flow per Screen

## Empty State

Read:

```text
savedSkincare.count
```

If:

```text
count == 0
```

render:

```text
EmptySkincareView
```

---

## Add Skincare

Read/write:

```text
SkincareDraft
```

No permanent persistence until user saves.

---

## Scanner

Input:

```text
Image
```

Output:

```text
OCRIngredientResult
```

Then:

```text
OCR Result
→ cosing
→ IngredientReference[]
```

---

## Current Skincare

Read:

```text
savedSkincare[]
```

Display:

```text
productName
category
```

---

## Match Ingredient

Read:

```text
savedSkincare[].ingredients
userAcneTypes
AcneIngredients
```

Compute:

```text
matchedIngredients
```

---

## Ingredient Detail

Read:

```text
ingredientID
```

Then fetch:

```text
IngredientReference
+
IngredientEvidence
```

---

# 25. Recommended Folder Structure

Untuk SwiftUI project:

```text
Features/
└── Skincare/
    ├── Views/
    │   ├── SkincareView.swift
    │   ├── EmptySkincareView.swift
    │   ├── AddSkincareView.swift
    │   ├── SkincareListView.swift
    │   ├── IngredientScannerView.swift
    │   ├── ScanInstructionView.swift
    │   ├── MatchIngredientView.swift
    │   └── IngredientDetailView.swift
    │
    ├── Components/
    │   ├── SkincareCard.swift
    │   ├── IngredientRow.swift
    │   ├── IngredientSearchField.swift
    │   ├── MatchedIngredientCard.swift
    │   └── SkincareCategorySelector.swift
    │
    ├── ViewModels/
    │   ├── SkincareViewModel.swift
    │   ├── SkincareFormViewModel.swift
    │   ├── IngredientScannerViewModel.swift
    │   └── IngredientMatchViewModel.swift
    │
    ├── Models/
    │   ├── SkincareProduct.swift
    │   ├── SkincareDraft.swift
    │   ├── IngredientReference.swift
    │   ├── MatchedIngredient.swift
    │   └── SkincareCategory.swift
    │
    ├── Services/
    │   ├── SkincareRepository.swift
    │   ├── IngredientRepository.swift
    │   ├── AcneIngredientRepository.swift
    │   ├── OCRService.swift
    │   └── IngredientMatchingService.swift
    │
    └── Resources/
        ├── cosing.json
        └── AcneIngredients.json
```

Jika project sudah mempunyai struktur global seperti `Models`, `Services`, dan `Repositories`, feature folder tidak perlu menduplikasi struktur tersebut.

---

# 26. Repository Responsibilities

## IngredientRepository

```swift
protocol IngredientRepository {
    func search(query: String) async throws -> [IngredientReference]
    func findByID(_ id: String) async throws -> IngredientReference?
}
```

Source:

```text
cosing
```

---

## AcneIngredientRepository

```swift
protocol AcneIngredientRepository {
    func ingredients(
        matching acneTypes: Set<AcneType>
    ) async throws -> [String]
}
```

Source:

```text
AcneIngredients
```

---

# 27. Matching Service

Jangan menaruh algorithm matching di ViewModel.

Gunakan:

```swift
protocol IngredientMatchingService {
    func match(
        skincareIngredients: [IngredientReference],
        acneTypes: Set<AcneType>
    ) async throws -> [MatchedIngredient]
}
```

Benefit:

- mudah di-test;
- tidak bergantung pada SwiftUI;
- mudah mengganti sumber database;
- logic dapat digunakan kembali.

---

# 28. OCR Service

Pisahkan OCR implementation dari UI:

```swift
protocol OCRService {
    func recognizeText(from image: UIImage) async throws -> String
}
```

Kemudian ingredient extraction juga sebaiknya dipisahkan:

```swift
protocol IngredientExtractionService {
    func extractIngredients(
        from text: String
    ) async throws -> [IngredientReference]
}
```

Sehingga:

```text
Camera
 ↓
OCRService
 ↓
Raw Text
 ↓
IngredientExtractionService
 ↓
cosing
 ↓
IngredientReference[]
```

---

# 29. Error States yang Perlu Disiapkan

Minimal:

```text
OCR failed
Image unavailable
Camera permission denied
Gallery unavailable
Ingredient not found
Database unavailable
Save failed
Delete failed
Matching failed
```

Tidak semuanya harus mempunyai desain baru.

Untuk boilerplate awal cukup siapkan:

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

# 30. Loading States

Minimal:

```text
Loading skincare
Scanning image
Searching ingredient
Matching ingredients
Saving skincare
```

Jangan menggunakan satu global loading state untuk seluruh flow jika beberapa proses dapat berjalan independen.

Contoh:

```swift
@Published var isScanning = false
@Published var isSearchingIngredient = false
@Published var isSaving = false
@Published var isMatching = false
```

---

# 31. Persistence Strategy

Untuk tahap boilerplate, tentukan terlebih dahulu:

```text
User-generated data
    → Persistent Storage

Reference data
    → Read-only JSON / bundled database

OCR result
    → Temporary state
```

Dengan demikian:

```text
SkincareProduct
    → persist

cosing
    → reference

AcneIngredients
    → reference

OCRIngredientResult
    → temporary
```

Ini penting agar hasil OCR tidak memenuhi storage dan tidak dianggap sebagai source of truth.

---

# 32. Implementation Plan

## Phase 1 — Data Contract

Buat terlebih dahulu:

```text
SkincareCategory
AcneType
IngredientReference
SkincareDraft
SkincareProduct
MatchedIngredient
IngredientEvidence
```

Output:

```text
Models compile
```

Belum perlu UI kompleks.

---

## Phase 2 — Load Reference Data

Implement:

```text
cosing loader
AcneIngredients loader
```

Test:

```text
Search "azelaic"
→ Azelaic Acid
```

dan:

```text
Papules + Whitehead
→ matched ingredients
```

---

## Phase 3 — Skincare Persistence

Implement:

```text
SkincareRepository
```

Test:

```text
save
fetch
delete
saveAll
```

Pastikan empty state dapat ditentukan hanya dari:

```swift
savedSkincare.isEmpty
```

---

## Phase 4 — Add Skincare Form

Implement:

```text
AddSkincareView
SkincareFormViewModel
```

Fokus:

```text
Category
Product Name
Ingredient List
Validation
Save Skincare
```

Gunakan dummy ingredient terlebih dahulu jika OCR belum siap.

---

## Phase 5 — Ingredient Search

Implement:

```text
IngredientRepository
IngredientSearchField
IngredientSearchResult
```

User dapat:

```text
type
→ search cosing
→ select
→ add
```

Tambahkan duplicate prevention.

---

## Phase 6 — OCR

Implement:

```text
Camera
Gallery
OCRService
IngredientExtractionService
```

Flow:

```text
Image
→ OCR
→ extract
→ normalize
→ cosing
→ confirmation
```

Jangan langsung save OCR result.

---

## Phase 7 — Skincare List

Implement:

```text
CurrentSkincareSection
SkincareCard
AddNewSkincare
Delete
```

Kemudian implement:

```text
Save All
```

dan seluruh alert state.

---

## Phase 8 — Match Ingredient

Implement:

```text
IngredientMatchingService
IngredientMatchViewModel
MatchIngredientSection
```

Input:

```text
user acne types
+
all skincare ingredients
```

Output:

```text
unique matched ingredients
```

---

## Phase 9 — Detail Pages

Implement:

```text
SkincareListView
MatchIngredientView
IngredientDetailView
```

Navigation harus menggunakan ID, bukan object copy jika data reference cukup besar.

Contoh:

```text
ingredientID
    ↓
IngredientDetailView
    ↓
repository.findByID()
```

---

# 33. Testing Plan

## Unit Test — Ingredient Normalization

```text
" AZELAIC ACID "
→ "azelaic acid"

"Azelaic   Acid"
→ "azelaic acid"
```

---

## Unit Test — Ingredient Search

```text
Query:
"azelaic"

Expected:
Azelaic Acid
```

---

## Unit Test — Duplicate

```text
Add:
Azelaic Acid
Azelaic Acid

Expected:
1 ingredient
```

---

## Unit Test — Matching

```text
Acne:
Papules

Ingredient:
Azelaic Acid

Database:
Azelaic Acid → Papules

Expected:
matched
```

---

## Unit Test — No Match

```text
Acne:
Cysts

Ingredient:
X

Database:
X → Papules

Expected:
not matched
```

---

## Unit Test — Delete Last

```text
Products:
[Cleanser]

Delete cleanser
→ show keep-empty confirmation

Cancel
→ [Cleanser]

Keep Empty
→ []
→ Empty State
```

---

## Unit Test — Save Empty

```text
Products:
[]

Save All

→ confirmation

Cancel
→ []

Keep Empty
→ []
```

---

# 34. State Matrix

| State | Data | Primary UI | Action |
|---|---|---|---|
| Empty | `savedSkincare = []` | Empty State | Add Routine |
| Add Form | `draft` | Add Skincare Form | Fill data |
| Category Selection | `draft.category` | Category selector | Select |
| Scan Initial | `draft.ingredients = []` | Scan prompt | Camera/Gallery |
| Scanning | `isScanning = true` | Scanner/loading | Capture |
| OCR Result | OCR result | Ingredient list | Confirm/edit |
| Manual Search | `searchQuery` | Search | Select |
| Ingredients Added | `draft.ingredients` | Ingredient list | Add/remove |
| Skincare Added | `pendingSkincare` | Skincare list | Add new/save all |
| Multiple Skincare | `pendingSkincare.count > 1` | List | Delete/add |
| Delete Last | `count == 1` | Alert | Cancel/Keep Empty |
| Saved | `savedSkincare` | Current Skincare | See detail |
| Matched | `matchedIngredients` | Match Ingredient | Open detail |
| Ingredient Detail | `ingredientID` | Detail | Expand/source |

---

# 35. Recommended MVP Scope

Untuk menghindari boilerplate terlalu besar, implementasi pertama cukup sampai:

```text
1. Models
2. cosing loader
3. AcneIngredients loader
4. SkincareRepository
5. SkincareViewModel
6. AddSkincareView
7. Ingredient Search
8. Dummy OCR result
9. Save/Delete
10. Matching algorithm
11. Current Skincare
12. Match Ingredient
```

Setelah flow tersebut stabil:

```text
13. Real OCR
14. Camera
15. Gallery
16. Scan Instruction
17. Ingredient Detail
18. Evidence / Sources
19. Error handling
20. Persistence refinement
```

---

# 36. Urutan Pengerjaan yang Disarankan

Jangan mulai dari camera/OCR.

Urutan paling aman:

```text
Models
  ↓
Reference Data
  ↓
Repositories
  ↓
Matching Algorithm
  ↓
Skincare Persistence
  ↓
Skincare ViewModel
  ↓
Add Skincare Form
  ↓
Ingredient Search
  ↓
Save/Delete
  ↓
Skincare Home
  ↓
Match Ingredient
  ↓
Navigation / Detail
  ↓
OCR
  ↓
Camera + Gallery
  ↓
Polishing
```

Alasannya: **OCR adalah input method**, bukan core data model.

Jika data model dan ingredient matching sudah benar, OCR nantinya hanya menggantikan:

```text
Manual Ingredient Input
```

menjadi:

```text
OCR → Ingredient Input
```

tanpa perlu mengubah struktur `SkincareProduct`.

---

# 37. Final Architecture

Target architecture:

```text
                     ┌──────────────────┐
                     │   SkincareView   │
                     └────────┬─────────┘
                              │
                     ┌────────▼─────────┐
                     │ SkincareViewModel│
                     └────────┬─────────┘
                              │
             ┌────────────────┼────────────────┐
             │                │                │
             ▼                ▼                ▼
      SkincareRepository  IngredientRepo  MatchService
             │                │                │
             ▼                ▼                ▼
       User Skincare         cosing       AcneIngredients
             │
             ▼
      SkincareProduct
             │
             ├───────────────┐
             │               │
             ▼               ▼
    Current Skincare    Match Ingredient
                             │
                             ▼
                    Ingredient Detail
```

OCR berada sebagai input pipeline terpisah:

```text
Camera / Gallery
       ↓
   OCRService
       ↓
Raw Text
       ↓
IngredientExtractionService
       ↓
IngredientRepository (`cosing`)
       ↓
IngredientReference[]
       ↓
SkincareDraft
```

## Prinsip utama

1. **`SkincareProduct` adalah user data.**
2. **`cosing` adalah reference data untuk canonical ingredient.**
3. **`AcneIngredients` adalah reference data untuk matching.**
4. **Acne condition berasal dari Home / Scan, bukan dihitung ulang di Skincare.**
5. **OCR hanya bertugas mengekstrak text; OCR bukan source of truth.**
6. **Ingredient yang disimpan sebaiknya menggunakan canonical ID dari `cosing`.**
7. **Draft form dipisahkan dari persisted skincare.**
8. **Matching algorithm dipisahkan dari SwiftUI View.**
9. **Delete last product dan save-empty merupakan dua alert flow yang berbeda.**
10. **Camera dan Gallery menggunakan OCR pipeline yang sama.**
