# Panduan Implementasi Fitur

Dokumen ini menjadi pusat bagi semua instruksi dan langkah praktis saat membuat fitur baru di Suzuran. Tujuannya adalah menyatukan proses, struktur, aturan, dan pengecekan agar implementasi fitur baru konsisten.

## Tujuan

- Mencegah penyebaran logika fitur ke kode root atau lapisan yang salah.
- Menjaga struktur lapisan tetap bersih.
- Membuat proses fitur baru mudah diikuti untuk siapa saja.
- Memastikan setiap fitur baru memiliki factory komposisi, implementasi domain, dan routing yang benar.

## Kapan Menggunakan Panduan Ini

Gunakan panduan ini setiap kali:

- ada fitur baru yang akan menjadi layar atau flow baru,
- ada fitur baru yang memerlukan data remote/local,
- ada proses bisnis baru yang perlu dipisahkan dari UI,
- ada fitur yang harus terdaftar dalam navigasi app.

## Langkah Utama Implementasi Fitur Baru

### 1. Tentukan batas fitur

Sebelum menulis kode, jawab pertanyaan berikut:

- Apa tujuan bisnis fitur ini?
- Data apa yang diperlukan?
- Jenis layar atau interaksi apa yang dibutuhkan?
- Apakah fitur ini membutuhkan route app-level?

Hasil dari jawaban ini menentukan namespace fitur dan struktur folder.

### 2. Buat folder fitur

Buat folder baru di:

```
Features/<NamaFitur>/
  Composition/
  Domain/
  Data/
  Presentation/
```

Jika fitur sederhana, struktur ini tetap dipertahankan untuk konsistensi.

### 3. Domain: definisikan aturan bisnis

Di `Features/<NamaFitur>/Domain/` buat:

- `Entities/`: model bisnis yang menjelaskan data utama.
- `Repositories/`: protokol akses data.
- `UseCases/`: aksi domain atau aturan bisnis.
- `Errors/`: error domain khusus.

Contoh isi:

- `AcneAnalysis.swift`
- `AcneAnalysisRepository.swift`
- `AnalyzeAcneFromImageUseCase.swift`
- `GetAcneAnalysisHistoryUseCase.swift`
- `AcneAnalysisDomainError.swift`

Aturan:

- Domain hanya mengenal konsep bisnis.
- Domain tidak mengimpor `SwiftUI`, `UIKit`, atau implementasi data.
- Gunakan protokol repository untuk menyembunyikan detail penyimpanan.

### 4. Data: implementasi akses data

Di `Features/<NamaFitur>/Data/` buat:

- `DTOs/`: bentuk payload API atau penyimpanan.
- `DataSources/`: protokol dan implementasi remote/local.
- `Mappers/`: konversi antara DTO dan Entity.
- `Repositories/`: implementasi protokol repository.

Contoh isi:

- `AcneAnalysisResponseDTO.swift`
- `AcneDetectionRemoteDataSource.swift`
- `InMemoryAcneHistoryLocalDataSource.swift`
- `AcneAnalysisMapper.swift`
- `DefaultAcneAnalysisRepository.swift`

Aturan:

- DTO hanya hidup di layer Data.
- `Data` boleh menggunakan `Infrastructure` untuk networking atau persistence.
- Model yang dipakai di `Presentation` harus dibuat melalui mapper di layer Data atau Presentation.

### 5. Presentation: tampilan dan state

Di `Features/<NamaFitur>/Presentation/` buat:

- `Models/`: state tampilan dan model UI.
- `ViewModels/`: observable object yang mengelola state.
- `Views/`: SwiftUI view.
- `Mapping/`: konversi entity domain ke model tampilan.

Contoh isi:

- `ExampleFeatureViewState.swift`
- `ExampleFeatureViewModel.swift`
- `ExampleFeatureView.swift`
- `ExampleFeaturePresentationMapper.swift`
- `ExampleFeatureErrorTextMapper.swift`

Aturan:

- ViewModel hanya mempublikasikan state.
- View hanya menggambar state tersebut.
- Hindari memasukkan logika bisnis langsung ke view.

### 6. Composition: merakit fitur

Di `Features/<NamaFitur>/Composition/` buat factory seperti:

- `ExampleFeatureFactory.swift`

Fungsi factory:

- membuat repository konkret,
- membuat use case,
- membuat mapper presentasi,
- membuat view model,
- membuat view fitur jika perlu.

Aturan:

- factory menjaga detail konstruksi tersembunyi dari view.
- jika fitur membutuhkan dependensi tambahan, tambahkan parameter pada factory.

### 7. App-level entry point dan navigasi

Jika fitur akan ditampilkan sebagai halaman app-level, lakukan berikut:

1. Tambahkan case baru di `App/AppRoute.swift`.
2. Tambahkan builder `navigationDestination(for:)` di `App/Root/RootView.swift`.
3. Buat factory method di `App/AppContainer.swift` untuk membuat view model atau view fitur.
4. Pastikan `RootViewModel` tetap hanya mengelola fase startup.
5. Jika navigasi dipicu dari halaman lain, teruskan closure navigasi dari root view.

Contoh:

- route case: `case ingredientOcr`
- builder: `ImagePickerPOCView()` atau view fitur lain.

Aturan:

- navigasi tidak boleh dikendalikan oleh view model domain.
- app/root layer mengelola route path.
- view fitur menerima action navigasi jika perlu.

### 8. Kepemilikan state dan injeksi

- Buat view model dengan `@StateObject` di pemilik yang bertanggung jawab.
- terima view model dengan `@ObservedObject` di child view.
- jangan membuat observable object di dalam `body` yang sering direcompute.

Contoh benar:

- `RootView` memiliki `HomeViewModel` sebagai `@StateObject`.
- `HomeView` menerima view model tersebut sebagai `@ObservedObject`.

### 9. Pengujian fitur

Setidaknya pertimbangkan:

- Use case tests untuk logika bisnis.
- Repository tests untuk mapping dan fallback.
- ViewModel tests untuk transisi state.

Jika fitur menggunakan dependensi eksternal, gunakan mock/protocol untuk isolasi.

### 10. Review gate

Sebelum merge, pastikan:

- tidak ada arah dependensi terlarang,
- penamaan file dan tipe sesuai konvensi,
- fitur tidak mencampur domain dan presentation,
- route app-level didaftarkan di layer App,
- dokumentasi fitur ada di `Documentation/` jika perlu.

## Aturan Penamaan Singkat untuk Fitur

- Tipe dan file: `UpperCamelCase`.
- Variabel, fungsi, properti: `lowerCamelCase`.
- Protokol: kata benda atau kata benda dengan kemampuan (`Repository`, `Logging`).
- Gunakan suffix per peran: `View`, `ViewModel`, `UseCase`, `Repository`, `Mapper`, `DTO`, `Factory`.
- Gunakan folder jamak: `Entities`, `UseCases`, `Repositories`, `ViewModels`, `DTOs`.
- Jangan gunakan nama generik seperti `Helper.swift` atau `Utils.swift` tanpa konteks.

## Catatan Tambahan

- `ExampleFeature` adalah contoh pola penuh yang dapat diikuti.
- Jika fitur tidak memerlukan app-level route, tetap gunakan struktur yang sama agar konsistensi terjaga.
- Simpan logika inisialisasi di factory dan biarkan view model fokus pada state.
