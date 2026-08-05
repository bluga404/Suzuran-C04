# Panduan App Flow

Dokumen ini menggabungkan konsep launch screen, startup flow, dan komposisi aplikasi tingkat atas. Tujuannya adalah menjelaskan bagaimana Suzuran memulai, bagaimana navigasi root bekerja, dan bagaimana fitur baru harus terhubung tanpa mencampur tanggung jawab.

## Tujuan

- Menjaga alur startup tetap bersih dan dapat diprediksi.
- Memisahkan fase aplikasi dari state fitur.
- Menjaga komposisi dependency di level app/root.
- Menetapkan cara menambahkan entry point fitur baru dengan aman.

## Sekilas App Flow Suzuran

1. `SuzuranApp` membuat `AppContainer.live()`.
2. `AppContainer` merangkai dependency global dan view model root.
3. `SuzuranApp` menempatkan `RootView` sebagai konten utama.
4. `RootView` menampilkan isi berdasarkan `RootViewModel.phase`.
5. `RootViewModel` menjalankan bootstrap aplikasi.
6. Setelah startup selesai, `RootView` menampilkan halaman awal atau error.
7. Navigasi root ditangani oleh `AppRouter` dan `NavigationStack`.

## Peran Setiap File di App Flow

- `SuzuranApp.swift`
  - entri aplikasi SwiftUI.
  - membuat `AppContainer`.
  - menyuntikkan `RootView`.

- `AppContainer.swift`
  - pusat komposisi dependency untuk app-level.
  - membuat `RootViewModel`.
  - menyiapkan factory untuk fitur entry.

- `AppBootstrapper.swift`
  - menjalankan inisialisasi awal.
  - mengelola first-launch flag dan setup environment.

- `AppEnvironment.swift`
  - menyimpan dependensi global seperti `AppLogger` dan `KeyValueStore`.

- `RootViewModel.swift`
  - mengelola fase startup: `launching`, `ready`, `failed`.
  - memanggil `bootstrapper.bootstrap()` dan menangani retry.

- `RootView.swift`
  - menampilkan loading, error, atau halaman utama.
  - membuat `AppRouter` dan `HomeViewModel` di owner yang benar.
  - mengatur `NavigationStack(path: $router.path)`.

- `AppRoute.swift` dan `AppRouter.swift`
  - mendefinisikan tujuan navigasi aplikasi.
  - mengontrol jalur dan push/pop route.

## Launch Screen dan Startup Flow

### Aturan Launch Screen

- Gunakan launch screen sistem di `LaunchScreen.storyboard`.
- Tidak membuat delay atau animasi buatan pada startup.
- Launch screen harus statis dan cepat diganti oleh UI pertama.
- Jangan letakkan logika async atau inisialisasi di storyboard.

### Kenapa Ini Penting

- Memenuhi panduan Apple HIG untuk launch screen.
- Menghindari pengalaman splash screen yang lambat.
- Menjaga aplikasi terlihat responsif saat membuka.

### Startup Flow yang Benar

- Root startup bekerja setelah tampilan aplikasi diinisialisasi.
- `RootViewModel` mengelola hanya fase startup, bukan fitur.
- `RootView` memetakan setiap fase ke tampilan yang sesuai.
- Jika startup gagal, tampilkan error screen dengan retry.

## Komposisi Aplikasi Tingkat Atas

### Kontrak App-Level

- `SuzuranApp` memulai aplikasi dan menyuntikkan root view.
- `AppContainer` merakit dependency dan membuat objek app-level.
- `RootViewModel` hanya mengelola fase startup.
- `RootView` mengelola tampilan root dan navigasi app-level.

### Aturan Wajib

1. `RootViewModel` tidak membuat feature view model.
2. Feature view model dibuat di `AppContainer` atau factory fitur.
3. Navigasi app-level dikendalikan oleh root layer.
4. View hanya menggambar state dan memicu action.

### Alur Komposisi

- `AppContainer` membangun semua dependency global.
- `RootView` membuat dan memegang `AppRouter`.
- `RootView` sebaiknya membuat feature view model hanya jika itu adalah entry point fitur.
- Semua pembuatan objek fitur sebaiknya dikendalikan oleh app/root, bukan di view atau view model fitur sendiri.

## Menambahkan Entry Point Fitur Baru

### Langkah Umum

1. Tambahkan route baru di `AppRoute`.
2. Tambahkan `navigationDestination(for:)` di `RootView`.
3. Buat factory feature di `AppContainer` atau feature factory.
4. Teruskan view model dan action navigasi ke view fitur.
5. Jangan ubah `RootViewModel` kecuali logika startup berubah.

### Contoh Singkat

- Tambahkan `case ingredientOcr` di `AppRoute`.
- Tambahkan `NavigationStack` builder untuk `ImagePickerPOCView()`.
- Jika fitur memerlukan view model, buat method factory di `AppContainer`.

## Kepemilikan State

- Buat objek observable dengan `@StateObject` pada pemilik view.
- Child menerima objek dengan `@ObservedObject`.
- Jangan membuat observable object di dalam `body` view yang sering dieksekusi ulang.

Contoh benar:

- `RootView` memiliki `HomeViewModel` sebagai `@StateObject`.
- `HomeView` menerima `HomeViewModel` sebagai `@ObservedObject`.

## Anti-Pattern yang Harus Dihindari

- `RootViewModel` dengan banyak metode `makeXViewModel()`.
- `ViewModel` membuat client infrastruktur seperti `URLSession` atau `UserDefaults`.
- `ViewModel` yang bergantung pada tipe `SwiftUI`.
- Pembuatan route tersebar di banyak view.

## Catatan Praktis

- App flow adalah tentang batas tanggung jawab antara startup, navigasi, dan fitur.
- Fitur yang lebih kompleks harus tetap dibangun dalam boundary `Features/<NamaFitur>/...`.
- Root app flow harus tetap sederhana, seiring bertambahnya jumlah layar.
- Jika fitur tidak perlu app-level route, tetap gunakan composition factory di folder fitur.
