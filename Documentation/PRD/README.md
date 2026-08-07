# PRD - ML Scoring V2

Dokumen ini menjelaskan integrasi model acne detection terbaru pada branch `Tech/ml-scoring-v2`.

## Tujuan

Mendokumentasikan bagaimana model, service, dan UI feature scan saling terhubung supaya implementasi mudah dipahami dan mudah diteruskan.

## Ruang Lingkup

- Struktur direktori model dan feature scan.
- Service yang dipakai untuk kamera dan inference.
- Cara mengintegrasikan model ke aplikasi iOS.
- Use case penggunaan feature.

## Dokumen Terkait

- [1. Struktur Direktori](./01_Directory_Structure.md)
- [2. Service Yang Digunakan](./02_Service_Overview.md)
- [3. Integrasi Model Ke Aplikasi](./03_Model_Integration.md)
- [4. Use Case Feature](./04_Use_Cases.md)

## Ringkasan Singkat

- Model utama terbaru ada di `Suzuran/best.mlpackage`.
- Model lama `Suzuran/yolov26s_67_4.mlpackage` masih ada sebagai aset historis.
- Feature scan memakai `CameraService` untuk kamera dan `PredictionService` untuk inference.
- Hasil deteksi dirender sebagai bounding box pada `ScanView`.
