# 3. Cara Mengintegrasikan Model Dengan Aplikasi

Bagian ini menjelaskan alur integrasi model ke aplikasi iOS.

## Alur Integrasi

```text
Model (.mlpackage)
  -> dikompilasi Xcode menjadi .mlmodelc
  -> dimuat oleh PredictionService
  -> dijalankan dengan Vision
  -> output MLMultiArray diparse jadi deteksi
  -> hasil ditampilkan di UI
```

## Langkah Integrasi

### 1. Masukkan model ke target aplikasi

- Simpan model di folder app, misalnya `Suzuran/best.mlpackage`.
- Pastikan file model ikut masuk ke target build.
- Xcode akan mengompilasi model tersebut saat build.

### 2. Load model dari bundle

- `PredictionService` mengambil model dari `Bundle.main`.
- Nama resource harus sama dengan nama package model.
- Jika model terbaru bernama `best.mlpackage`, resource yang dipanggil harus konsisten dengan nama itu.

### 3. Bungkus model dengan Vision

- Model dimasukkan ke `VNCoreMLModel`.
- Inference dijalankan lewat `VNCoreMLRequest`.
- `imageCropAndScaleOption` diset ke `.scaleFill` agar input gambar sesuai ukuran model.

### 4. Kirim gambar dari kamera atau galeri

- Dari kamera: `CameraService` mengembalikan `UIImage` hasil capture.
- Dari galeri: `PhotosPicker` mengirim `Data`, lalu diubah menjadi `UIImage`.

### 5. Parse output model

- Output model terbaru berbentuk `MLMultiArray` dengan shape `[1, 300, 6]`.
- Enam nilai tersebut dipakai untuk:
  - koordinat bounding box
  - confidence
  - class id
- Hasil parsing dibuat menjadi array `AcneDetection`.

### 6. Tampilkan hasil ke layar

- `ScanViewModel` menyimpan hasil prediksi ke state.
- `ScanView` menampilkan gambar, bounding box, dan ringkasan hasil.
- `DetectionsOverlayView` dan `BoundingBoxView` dipakai untuk render overlay.

## Hal Yang Harus Dijaga

- Urutan class pada model harus sama dengan `classNames` di `PredictionService`.
- Jika model dilatih ulang dengan jumlah class berbeda, parser dan mapping label harus ikut diperbarui.
- Jika nama file model berubah, update juga nama resource yang dibaca dari bundle.
- Jika output model berubah format, parsing `MLMultiArray` harus disesuaikan.

## Output Yang Diharapkan

- Prediksi class acne muncul di hasil akhir.
- Bounding box muncul di atas gambar.
- Warna box mengikuti label class.
- Result card menampilkan top prediction dengan confidence.
