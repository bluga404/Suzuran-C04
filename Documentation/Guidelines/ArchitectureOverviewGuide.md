# Ikhtisar Arsitektur dan Struktur Proyek

Dokumen ini menggabungkan panduan arsitektur, struktur proyek, dan aturan dependensi Suzuran. Tujuannya adalah menjelaskan secara jelas apa yang ada di setiap lapisan, kapan file baru dibuat, dan bagaimana fitur baru harus diintegrasikan.

## Prinsip Arsitektur

Suzuran dibangun di atas beberapa prinsip utama:

- **Clean Architecture**: memisahkan domain bisnis dari detail UI dan data.
- **MVVM**: menjadikan SwiftUI view sebagai representasi dari state yang dikelola view model.
- **Composition Root**: menyatukan semua pembuatan dependency di satu tempat yang mudah dilacak.

## Lapisan Utama dan Perannya

### `App`

Digunakan untuk startup, konfigurasi global, dan navigasi root.

- `SuzuranApp.swift`: titik masuk aplikasi.
- `AppContainer.swift`: merakit dependency global dan factory fitur.
- `AppBootstrapper.swift`: inisialisasi awal seperti first-launch flag.
- `AppEnvironment.swift`: tempat menyimpan dependensi bersama seperti logger dan store.
- `Root/RootView.swift`: menampilkan halaman berdasarkan fase startup dan memegang app-level navigation.
- `Root/RootViewModel.swift`: mengelola state startup (`launching`, `ready`, `failed`).
- `Navigation/AppRoute.swift` dan `AppRouter.swift`: mendefinisikan tujuan dan jalur navigasi.

### `Core`

Menyimpan utilitas dan komponen yang digunakan di seluruh aplikasi.

- `DesignSystem`: warna, typography, spacing, radius, komponen tombol, kartu, dan state views.
- `Error`: error umum dan pemetaan error ke pesan pengguna.
- `Logging`: abstraksi logging.
- `Foundation`: konstanta aplikasi.
- `State`: model state umum.

### `Infrastructure`

Adapter platform untuk sistem dan API.

- `Networking`: endpoint, HTTP client, dan implementasi URLSession.
- `Persistence`: abstraksi penyimpanan seperti `KeyValueStore` dan `UserDefaultsKeyValueStore`.

### `Features`

Setiap fitur memiliki struktur yang sama:

- `Domain`: entitas bisnis, protokol repository, use case, dan error domain.
- `Data`: DTO, data source, mapper, dan implementasi repository.
- `Presentation`: view, view model, model state, dan mapping untuk tampilan.
- `Composition`: factory untuk merakit fitur.

## Contoh Struktur Fitur

```
Features/
  ExampleFeature/
    Composition/
    Domain/
    Data/
    Presentation/
```

## Arah Dependensi

Aturan dependensi yang harus diikuti:

- `App` → `Core`, `Features`, `Infrastructure`
- `Presentation` → `Domain`, `Core`
- `Data` → `Domain`, `Core`, `Infrastructure`
- `Domain` → `Core`
- `Core` → hanya `Foundation` atau kode internal `Core`

Artinya:

- Domain tidak boleh bergantung pada detail UI atau implementasi data.
- Presentation tidak boleh memanggil API atau langsung menggunakan DTO.
- Infrastructure hanya boleh digunakan sebagai adaptor sistem.

## Aturan Penempatan File

- `Domain/UseCases`: use case bisnis fitur.
- `Domain/Repositories`: protokol akses data.
- `Data/Repositories`: implementasi protokol repository.
- `Data/DTOs`: payload API atau bentuk penyimpanan.
- `Data/Mappers`: konversi DTO ⇄ entitas domain.
- `Presentation/Mapping`: konversi domain ke model tampilan.
- `Presentation/Models`: state tampilan dan struktur tampilan.

## Contoh Pelanggaran dan Perbaikan

1. **ViewModel memanggil `URLSession` langsung**
   - Pindahkan logika ke repository di `Data`, dengan protokol di `Domain`.

2. **View menggunakan DTO secara langsung**
   - Map DTO ke entitas domain, lalu ke model tampilan.

3. **Warna dan font hardcoded di tiap view**
   - Gunakan token desain `Core/DesignSystem/Tokens`.

4. **Singleton global tersebar**
   - Injeksi dependency melalui `AppContainer` atau factory fitur.

5. **RootView menunggu delay splash**
   - Gunakan launch screen sistem dan tampilkan UI saat startup selesai.

6. **RootViewModel membuat banyak view model fitur**
   - Biarkan `AppContainer` atau factory fitur yang membuat view model.

7. **ViewModel fitur mengontrol navigasi app-level**
   - Berikan closure navigasi dari `RootView` atau `AppContainer`.

8. **ViewModel dibuat ulang di `body` view**
   - Buat sekali dengan `@StateObject`, terima sebagai `@ObservedObject`.

## Konvensi Penamaan

Konvensi ini membantu menjaga konsistensi dan memudahkan pengembang membaca kode. Gunakan gaya penamaan yang jelas dan sesuai peran file atau simbol.

### Tipe dan Nama File

- Tipe: gunakan `UpperCamelCase`.
  - Contoh: `HomeView`, `AppContainer`, `AcneAnalysisRepository`.
- Nama file: cocokkan dengan nama tipe utama di dalamnya.
  - Contoh: `HomeView.swift` berisi `struct HomeView`.
- Satu file, satu tipe utama. Jika ada helper kecil, letakkan di file yang sama atau buat extension jika perlu.

### Suffix Berdasarkan Peran

Gunakan akhiran yang konsisten untuk menjelaskan peran tipe:

- `...View`: tampilan SwiftUI.
- `...ViewModel`: pengelola state tampilan.
- `...UseCase`: logika bisnis atau aksi domain.
- `...Repository`: kontrak akses data atau implementasi data.
- `...Mapper`: objek konversi data.
- `...DTO`: data transfer object untuk boundary API atau penyimpanan.
- `...Factory`: perakit objek atau view.

### Penamaan Folder

- Gunakan bentuk jamak untuk kategori: `Entities`, `UseCases`, `Repositories`, `ViewModels`, `DTOs`.
- Gunakan urutan fitur terlebih dahulu di `Features/<NamaFitur>/...`.
- Hindari folder generik seperti `Helpers` atau `Utils` jika bisa dikelompokkan lebih spesifik.

### Variabel, Fungsi, dan Properti

- Gunakan `lowerCamelCase`.
- Nama fungsi yang melakukan aksi: gunakan kata kerja.
  - Contoh: `loadHistory()`, `analyzeSampleImage()`.
- Nama fungsi yang mengembalikan nilai tanpa efek samping: gunakan frase deskriptif.
  - Contoh: `map(_:)`, `history()`.
- Nama properti: buat jelas dan sesuai konteks.
  - Contoh: `welcomeText`, `ingredientOcrButtonTitle`.

### Protokol

- Gunakan kata benda ketika menggambarkan kontrak.
  - Contoh: `AcneAnalysisRepository`.
- Gunakan akhiran kemampuan bila sesuai.
  - Contoh: `AppLogging`, `AppBootstrapping`.
- Hindari nama protokol yang terlalu generik seperti `Service`.

### Dokumentasi Kode

- Mulai komentar dengan apa yang dilakukan simbol tersebut.
- Gunakan markup Swift untuk parameter, return, dan throws.
- Buat komentar singkat, fokus pada alasan dan efek.

Contoh:

```swift
/// Mengambil riwayat analisis jerawat dari repository.
///
/// - Returns: daftar `AcneAnalysis` yang tersimpan.
/// - Throws: `AppError` jika terjadi kegagalan baca.
func execute() async throws -> [AcneAnalysis]
```

### Apa yang Harus Dihindari

- Jangan tambahkan nama tipe di nama variabel ketika perannya sudah jelas.
  - Salah: `var homeViewModelObject`
  - Benar: `var homeViewModel`
- Hindari singkatan yang tidak jelas.
- Jangan gunakan `Helper.swift`, `Utils.swift`, atau nama generik lain tanpa konteks.
- Hindari nama file yang tidak mencerminkan peran nyata kode di dalamnya.

## Catatan Komposisi Top-Level

- `SuzuranApp` hanya membuat `AppContainer` dan `RootView`.
- `AppContainer` adalah pusat pembuatan objek untuk app-level.
- `RootViewModel` hanya mengelola fase startup.
- `RootView` menangani route root dan render fase.
- Feature state harus dipisahkan dari app startup state.

## Mengapa `ExampleFeature` Penting

`ExampleFeature` berfungsi sebagai referensi untuk:

- pemisahan domain, data, presentation,
- penggunaan repository, data source, dan mapper,
- pembuatan view model dan view yang loyals pada MVVM.

Fitur ini memberikan contoh implementasi yang bisa dijadikan pola ketika fitur nyata ditambahkan.
