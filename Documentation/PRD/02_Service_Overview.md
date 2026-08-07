# 2. Service Yang Digunakan

Feature ini memakai dua service utama.

## CameraService

File: `Suzuran/Service/CameraService.swift`

Tanggung jawab:

- Meminta izin kamera.
- Menjalankan `AVCaptureSession`.
- Mengatur kamera depan dan belakang.
- Mengambil foto dari `AVCapturePhotoOutput`.
- Menyediakan frame video lewat `AVCaptureVideoDataOutput`.

Fungsi penting:

- `requestPermission()` untuk meminta akses kamera.
- `startSession()` untuk memulai kamera.
- `stopSession()` untuk menghentikan sesi.
- `toggleCamera()` untuk pindah kamera depan/belakang.
- `capturePhoto(completion:)` untuk mengambil foto dan mengirim `UIImage`.

## PredictionService

File: `Suzuran/Service/PredictionService.swift`

Tanggung jawab:

- Memuat model ML dari bundle aplikasi.
- Membuat `VNCoreMLRequest`.
- Menjalankan inference ke gambar yang masuk.
- Membaca output `MLMultiArray`.
- Mengubah output menjadi daftar `AcneDetection`.

Catatan penting:

- Model yang dibaca harus cocok dengan nama resource di bundle.
- Untuk branch ini, model terbaru ada di `best.mlpackage`.
- Output model dibaca sebagai tensor deteksi dengan 300 row dan 6 kolom per deteksi.
- Label class dipetakan ke:
  - `blackhead`
  - `cyst`
  - `nodule`
  - `papule`
  - `pustule`
  - `whitehead`

Fungsi penting:

- `predict(_:)` untuk menjalankan inference.
- `topPrediction(from:image:)` untuk mengambil hasil terbaik.
- `parseDetections(_:threshold:)` untuk parsing output model.
- `cgOrientation(from:)` untuk menyesuaikan orientasi gambar.

## ScanViewModel

File: `Suzuran/Feature/Scan/ViewModel/ScanViewModel.swift`

Tanggung jawab:

- Menjadi penghubung antara kamera, model, dan UI.
- Mengatur state seperti `idle`, `camera`, `processing`, dan `result`.
- Menyimpan hasil deteksi dan error message.

Alur utama:

1. User membuka feature scan.
2. ViewModel meminta permission kamera.
3. Kamera aktif atau user upload gambar.
4. Gambar dikirim ke `PredictionService`.
5. Hasil inference dipindahkan ke state UI.

## Utility Pendukung

- `AcneLabelColor` menentukan warna bounding box berdasarkan label.
- `CoordinateTransformer` mengubah koordinat model ke koordinat layar.
