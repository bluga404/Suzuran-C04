# Dokumentasi Contoh Fitur: Acne Detection

Dokumen ini menjelaskan struktur dan alur implementasi `ExampleFeature` sebagai referensi arsitektur lengkap untuk fitur Suzuran.

## Tujuan Fitur

Fitur ini adalah contoh pelaksanaan lengkap Clean Architecture + MVVM pada SwiftUI. Ia menunjukkan:

- cara memisahkan konsep bisnis dari tampilan,
- cara membuat repository dan data source,
- cara memetakan DTO ke entitas domain,
- cara menghubungkan view model dengan view.

## Struktur Fitur

`Features/ExampleFeature/` memiliki 4 bagian utama:

- `Composition/`
- `Domain/`
- `Data/`
- `Presentation/`

### `Composition/`

- `ExampleFeatureFactory.swift`

Fungsi:

- merakit dependency fitur.
- membuat repository konkret dengan remote dan local data source.
- membuat use case.
- membuat `ExampleFeatureViewModel`.
- membuat `ExampleFeatureView` jika diperlukan.

Kenapa penting:

Factory menjaga detail konstruksi fitur tidak tersebar ke view atau root app. Ini membuat fitur bisa diuji dan diganti lebih mudah.

### `Domain/`

Folder ini berisi kontrak dan definisi bisnis fitur.

- `Entities/AcneAnalysis.swift`
  - entitas bisnis yang merepresentasikan hasil analisis acne.
  - berisi `AcneSeverity`, `AcneFinding`, `FaceZone`, dan properti penting.

- `Errors/AcneAnalysisDomainError.swift`
  - error bisnis khusus yang menjelaskan kasus seperti data kosong atau validasi payload.

- `Repositories/AcneAnalysisRepository.swift`
  - kontrak akses data fitur.
  - mendefinisikan metode `analyze(imageData:capturedAt:)` dan `history()`.

- `UseCases/AnalyzeAcneFromImageUseCase.swift`
  - logika bisnis untuk memproses input gambar.
  - memeriksa data gambar kosong.
  - memeriksa tingkat confidence minimal.

- `UseCases/GetAcneAnalysisHistoryUseCase.swift`
  - logika mengambil riwayat analisis dari repository.

Mengapa di sini:

Domain adalah tempat aturan bisnis hidup. Semua data mentah harus diterjemahkan ke entitas domain sebelum digunakan oleh presentation.

### `Data/`

Folder ini berisi detail bagaimana data disediakan.

- `DTOs/AcneAnalysisResponseDTO.swift`
  - definisi data bentuk serialisasi yang dikembalikan remote atau disimpan lokal.
  - berbeda dari entitas domain karena menggunakan tipe string untuk beberapa nilai enumerasi.

- `DataSources/Remote/AcneDetectionRemoteDataSource.swift`
  - protokol untuk sumber data remote.
  - memungkinkan implementasi nyata atau mock.

- `DataSources/Remote/MockAcneDetectionRemoteDataSource.swift`
  - implementasi dummy untuk contoh dan pengembangan tanpa backend.
  - menghasilkan hasil analisis berdasarkan hash input.

- `DataSources/Local/AcneHistoryLocalDataSource.swift`
  - protokol untuk penyimpanan lokal.

- `DataSources/Local/InMemoryAcneHistoryLocalDataSource.swift`
  - implementasi lokal sementara yang menyimpan data di memori.

- `Mappers/AcneAnalysisMapper.swift`
  - menerjemahkan `AcneAnalysisResponseDTO` menjadi `AcneAnalysis`.
  - memvalidasi nilai `severity` dan `zone`.

- `Repositories/DefaultAcneAnalysisRepository.swift`
  - implementasi protokol `AcneAnalysisRepository`.
  - memanggil remote data source untuk analisis.
  - menyimpan hasil ke local data source.
  - memetakan response ke entitas domain.

Mengapa di sini:

Data layer memegang detail transport dan storage. Domain tidak boleh bergantung pada format payload, dan presentation tidak boleh mengetahui dari mana data berasal.

### `Presentation/`

Folder ini berisi UI dan state untuk fitur.

- `Mapping/ExampleFeaturePresentationMapper.swift`
  - menerjemahkan entitas domain `AcneAnalysis` menjadi model tampilan `AcneAnalysisCardModel`.

- `Mapping/ExampleFeatureErrorTextMapper.swift`
  - menerjemahkan error ke pesan pengguna.

- `Models/ExampleFeatureViewState.swift`
  - mendefinisikan enum state tampilan fitur.
  - contoh state: `.idle`, `.analyzing`, `.analysisResult`, `.history`, `.emptyHistory`, `.error`.

- `ViewModels/ExampleFeatureViewModel.swift`
  - memegang state presentasi dan logika event fitur.
  - memanggil use case domain ketika user menekan tombol.
  - hanya mengubah state, tidak berhubungan langsung dengan detail data source.

- `Views/ExampleFeatureView.swift`
  - menggambar tampilan berdasarkan `ExampleFeatureViewState`.
  - memisahkan content loading, empty, error, dan hasil.
  - menggunakan komponen UI dasar dari `Core/DesignSystem`.

Mengapa di sini:

Presentation hanya fokus pada tampilan. ViewModel berfungsi sebagai perantara antara UI dan domain.

## Alur Fitur Contoh

1. User menekan tombol "Run Sample Analysis".
2. `ExampleFeatureView` memanggil `viewModel.analyzeSampleImage()`.
3. `ExampleFeatureViewModel` mengubah state menjadi `.analyzing`.
4. `ExampleFeatureViewModel` memanggil `AnalyzeAcneFromImageUseCase.execute(...)`.
5. Use case memanggil repository `analyze(imageData:capturedAt:)`.
6. Repository `DefaultAcneAnalysisRepository` memanggil remote data source.
7. Remote data source mengembalikan `AcneAnalysisResponseDTO`.
8. Mapper mengubah DTO menjadi `AcneAnalysis`.
9. Use case mengembalikan `AcneAnalysis` ke view model.
10. View model memetakan ke model tampilan dan mengubah state menjadi `.analysisResult`.
11. `ExampleFeatureView` menampilkan hasilnya.

Jika terjadi error:

- error dipetakan ke `AppError` atau `AcneAnalysisDomainError`.
- `ExampleFeatureErrorTextMapper` mengubah error menjadi pesan pengguna.
- state berubah ke `.error`.

## Bagaimana Menggunakan Contoh Ini

- Ikuti pola `ExampleFeature` untuk fitur yang memiliki:
  - input kompleks,
  - validasi bisnis,
  - integrasi remote/local,
  - state tampilan banyak.
- Gunakan `ExampleFeatureFactory` sebagai model untuk membuat factory fitur baru.
- Gunakan `ExampleFeatureViewState` sebagai model state fitur, jangan biarkan view mengelola kondisi sendiri.

## Aturan Praktis untuk Fitur Baru

- Buat protokol repository di domain, bukan di data.
- Buat implementasi repository di data.
- Gunakan mapper untuk semua konversi DTO.
- Buat view model yang hanya mempublikasikan state.
- Buat view yang hanya menggambar state tersebut.
- Gunakan factory composition untuk merakit objek.
