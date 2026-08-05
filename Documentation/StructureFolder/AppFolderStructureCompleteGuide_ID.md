# Dokumentasi Lengkap Struktur App Suzuran

Dokumen ini menjelaskan struktur folder App secara menyeluruh, termasuk hubungan antar file, alasan implementasi, alur data, aturan arsitektur, potensi pelanggaran, dan panduan ketika aplikasi membesar.

Tujuan dokumen:
- Membantu developer baru memahami proyek dari nol.
- Menjelaskan kenapa pola arsitektur ini dipakai.
- Menjadi referensi saat menambah fitur baru agar tetap konsisten.

## 1. Gambaran Besar Arsitektur

Suzuran saat ini memakai gabungan:
- Clean Architecture untuk fitur referensi ExampleFeature.
- MVVM pada level presentasi (View + ViewModel).
- Composition Root pada AppContainer untuk merakit dependency.

Arah ketergantungan ideal:
- App boleh mengakses Core, Features, Infrastructure.
- Presentation boleh mengakses Domain dan Core.
- Data boleh mengakses Domain, Core, Infrastructure.
- Domain sebaiknya tidak tahu detail UI, SwiftUI, atau URLSession.

## 2. Peta Struktur dan Fungsi Utama



## 2.4 Features Layer

## 2.4.1 Feature Home

### File: Suzuran/Features/Home/Presentation/HomeViewModel.swift
Peran:
- Menyimpan ViewState sederhana teks welcome + tombol.

Cuplikan kunci:
~~~swift
struct ViewState { let welcomeText: String; let ingredientOcrButtonTitle: String }
~~~

### File: Suzuran/Features/Home/Presentation/HomeView.swift
Peran:
- Menampilkan welcome dan tombol ke Ingredient OCR.

Cuplikan kunci:
~~~swift
let onNavigateToIngredientOcr: () -> Void
~~~
Arti:
- Navigasi di-inject sebagai aksi, bukan hardcoded router di dalam HomeView.

## 2.4.2 Feature ingredientsOcr

File:
- Suzuran/Features/ingredientsOcr/ImagePickerPOCView.swift
- Suzuran/Features/ingredientsOcr/CameraPicker.swift
- Suzuran/Features/ingredientsOcr/IngredientOCRView.swift
- Suzuran/Features/ingredientsOcr/IngredientOCRService.swift
- Suzuran/Features/ingredientsOcr/IngredientParser.swift

Peran singkat:
- ImagePickerPOCView: pilih gambar gallery atau kamera.
- CameraPicker: bridge UIKit UIImagePickerController ke SwiftUI.
- IngredientOCRView: jalankan OCR dan tampilkan hasil.
- IngredientOCRService: panggil Vision VNRecognizeTextRequest.
- IngredientParser: ekstrak daftar ingredient dari raw text.

Cuplikan kunci:
~~~swift
let request = VNRecognizeTextRequest { request, error in ... }
~~~
Arti:
- OCR dijalankan oleh framework Vision milik Apple.

Cuplikan kunci:
~~~swift
ingredients = IngredientParser.extractIngredients(from: text)
~~~
Arti:
- Parsing dipisah dari OCR service agar lebih mudah diuji dan diubah.

Catatan arsitektur:
- Feature ini masih POC, belum mengikuti struktur Domain/Data/Presentation seperti ExampleFeature.

## 2.4.3 ExampleFeature sebagai Blueprint Arsitektur

Feature ini adalah contoh paling lengkap dan benar untuk pattern Clean Architecture.

### Composition
File: Suzuran/Features/ExampleFeature/Composition/ExampleFeatureFactory.swift

Cuplikan kunci:
~~~swift
let repository = DefaultAcneAnalysisRepository(remoteDataSource: MockAcneDetectionRemoteDataSource(), localDataSource: InMemoryAcneHistoryLocalDataSource())
~~~
Arti:
- Factory merakit semua dependency fitur di satu tempat.

### Domain
File utama:
- Entities/AcneAnalysis.swift
- Errors/AcneAnalysisDomainError.swift
- Repositories/AcneAnalysisRepository.swift
- UseCases/AnalyzeAcneFromImageUseCase.swift
- UseCases/GetAcneAnalysisHistoryUseCase.swift

Cuplikan kunci:
~~~swift
protocol AcneAnalysisRepository { func analyze(...); func history() }
~~~
Arti:
- Domain mendefinisikan kontrak kebutuhan data, bukan detail implementasi.

Cuplikan kunci:
~~~swift
guard analysis.confidence >= 0.2 else { throw AcneAnalysisDomainError.lowConfidence }
~~~
Arti:
- Aturan bisnis (business rule) disimpan di use case domain.

Istilah penting:
- Use case: satu aksi bisnis terfokus.
- Repository: kontrak akses data dari sudut domain.
- Entity: model inti bisnis, independen dari UI/API.

### Data
File utama:
- DTOs/AcneAnalysisResponseDTO.swift
- Mappers/AcneAnalysisMapper.swift
- DataSources/Remote/AcneDetectionRemoteDataSource.swift
- DataSources/Remote/MockAcneDetectionRemoteDataSource.swift
- DataSources/Local/AcneHistoryLocalDataSource.swift
- DataSources/Local/InMemoryAcneHistoryLocalDataSource.swift
- Repositories/DefaultAcneAnalysisRepository.swift

Cuplikan kunci:
~~~swift
return try records.map(AcneAnalysisMapper.map)
~~~
Arti:
- Data layer bertanggung jawab mengubah DTO ke Entity domain.

### Presentation
File utama:
- Models/ExampleFeatureViewState.swift
- Mapping/ExampleFeaturePresentationMapper.swift
- Mapping/ExampleFeatureErrorTextMapper.swift
- ViewModels/ExampleFeatureViewModel.swift
- Views/ExampleFeatureView.swift

Cuplikan kunci:
~~~swift
@Published private(set) var state: ExampleFeatureViewState = .idle
~~~
Arti:
- ViewModel expose state read-only dari luar, mengurangi mutasi liar.

Cuplikan kunci:
~~~swift
state = .error(message: ExampleFeatureErrorTextMapper.message(for: error))
~~~
Arti:
- Error dipetakan menjadi pesan UI yang konsisten.

## 3. Relasi Antar File dan Koneksi Nyata

## 3.1 Startup sampai Home
Urutan:
1. SuzuranApp membuat AppContainer.live().
2. AppContainer membuat AppEnvironment, AppBootstrapper, RootViewModel.
3. RootView dipasang dengan RootViewModel + Dependencies.
4. RootView onAppear memanggil RootViewModel.start().
5. RootViewModel menjalankan bootstrapper.bootstrap().
6. Jika sukses: phase menjadi ready dan HomeView tampil.
7. Jika gagal: phase failed dan ErrorStateView tampil.

Koneksi kunci:
- RootViewModel memakai AppBootstrapping, bukan AppBootstrapper konkret.
- AppBootstrapper memakai AppEnvironment, lalu AppEnvironment punya logger dan keyValueStore.

## 3.2 Home ke OCR
Urutan:
1. Pengguna menekan tombol di HomeView.
2. Closure onNavigateToIngredientOcr dipanggil.
3. RootView mengarahkan router.push(.ingredientOcr).
4. NavigationStack membuka ImagePickerPOCView.

Koneksi kunci:
- HomeView tidak import router.
- AppRoute menentukan destination yang legal.

## 3.3 Flow ExampleFeature
Urutan:
1. View panggil viewModel.analyzeSampleImage().
2. ViewModel panggil AnalyzeAcneFromImageUseCase.
3. Use case validasi input lalu panggil repository.analyze.
4. Repository panggil remote data source.
5. Repository simpan response ke local data source.
6. Mapper ubah DTO ke entity.
7. Presentation mapper ubah entity ke card model.
8. State UI diubah ke analysisResult.

## 4. Rules Arsitektur yang Sudah Terlihat

Rule 1:
- Pembuatan dependency di Composition Root, bukan di View.

Rule 2:
- Domain menyimpan aturan bisnis dan kontrak data.

Rule 3:
- Data bertugas mapping DTO ke Entity.

Rule 4:
- Presentation tidak memanggil URLSession langsung.

Rule 5:
- Token UI terpusat di DesignSystem.

Rule 6:
- Error dipetakan dahulu sebelum ditampilkan ke user.

## 5. Potensi Pelanggaran dan Risiko Saat Ini

1. ingredientsOcr belum Clean Architecture.
Dampak:
- Logic OCR, parsing, dan UI campur dalam feature POC.
- Sulit testing unit dan sulit scaling.

2. Feature Home masih presentation-only.
Dampak:
- Begitu butuh data network/persistence, struktur akan cepat membesar tanpa boundary jelas.

3. URLSessionHTTPClient belum terhubung ke feature nyata.
Dampak:
- Jalur production API belum tervalidasi end-to-end.

4. Local storage ExampleFeature masih in-memory.
Dampak:
- Riwayat hilang setiap app restart.

5. Logging hanya DEBUG print.
Dampak:
- Sulit observability pada production issue.

6. Belum ada test suite.
Dampak:
- Refactor berisiko merusak behavior tanpa terdeteksi cepat.

## 6. Rekomendasi Saat App Bertumbuh

## 6.1 Refactor ingredientsOcr mengikuti blueprint ExampleFeature
Tambahan struktur yang disarankan:
- Features/IngredientsOCR/Domain/Entities
- Features/IngredientsOCR/Domain/UseCases
- Features/IngredientsOCR/Domain/Repositories
- Features/IngredientsOCR/Data/DataSources
- Features/IngredientsOCR/Data/Repositories
- Features/IngredientsOCR/Presentation/ViewModels
- Features/IngredientsOCR/Presentation/Views
- Features/IngredientsOCR/Composition

Kenapa:
- Supaya OCR logic bisa diuji tanpa UI.
- Supaya gampang swap provider OCR di masa depan.

## 6.2 Tambah test layer demi layer
Prioritas:
- Unit test UseCase.
- Unit test Mapper.
- Unit test ViewModel state transitions.
- Snapshot/UI test untuk state views penting.

## 6.3 Hubungkan networking nyata
Langkah:
- Tambahkan real remote data source yang memakai HTTPClient.
- Tangani status code, decoding, retry policy.
- Tambahkan request header strategy (auth, locale, trace id).

## 6.4 Tingkatkan persistence
Langkah:
- Ganti in-memory history ke storage persisten (CoreData/SQLite/SwiftData).
- Tambahkan migration strategy untuk schema perubahan.

## 6.5 Observability production
Langkah:
- Tambahkan crash reporting.
- Tambahkan analytics event penting per use case.
- Buat logging level dan redaksi data sensitif.

## 6.6 Evolusi routing
Langkah:
- Jika route makin kompleks, ubah AppRoute agar bisa membawa payload.
Contoh:
~~~swift
case ingredientDetail(id: UUID)
~~~

## 7. Checklist Menambah Fitur Baru

Ikuti urutan ini agar konsisten:
1. Definisikan Entity dan Domain Error.
2. Definisikan protocol Repository di Domain.
3. Buat UseCase per aksi bisnis.
4. Buat DTO + Mapper di Data.
5. Buat remote/local data source.
6. Buat repository implementation.
7. Buat ViewState + ViewModel + View.
8. Buat Factory di Composition.
9. Daftarkan route jika perlu di AppRoute + Root destination.
10. Tambahkan test untuk use case, mapper, view model.

## 8. Istilah Penting untuk Developer Baru

ViewModel:
- Objek yang mengelola state UI dan aksi pengguna.
- View membaca state dari ViewModel, tidak menyimpan business logic berat.

Use case:
- Satu unit logika bisnis, misalnya analisis gambar atau ambil riwayat.

Repository:
- Kontrak akses data dari sudut domain.
- Implementasi sebenarnya ada di Data layer.

DTO:
- Data Transfer Object, bentuk data dari API atau storage.
- Biasanya belum cocok langsung dipakai UI.

Mapper:
- Pengubah data dari satu bentuk ke bentuk lain.
- Contoh: DTO ke Entity, Entity ke UI model.

Composition Root:
- Tempat merakit object graph dependency (di proyek ini: AppContainer).

## 9. Kesimpulan Praktis

Implementasi saat ini sudah memiliki fondasi arsitektur yang baik, terutama pada ExampleFeature. Area yang paling perlu ditingkatkan adalah menyamakan kualitas ingredientsOcr agar mengikuti pola yang sama, kemudian menambahkan test dan integrasi networking nyata. Jika langkah ini dilakukan, codebase akan lebih stabil, mudah dipahami developer baru, dan lebih siap untuk scaling fitur produk.
