# 1. Struktur Direktori

Bagian ini menjelaskan struktur folder yang relevan untuk feature ML scoring dan acne detection.

## Struktur Utama

```text
Suzuran/
├── best.mlpackage/
│   ├── Manifest.json
│   └── Data/com.apple.CoreML/model.mlmodel
├── yolov26s_67_4.mlpackage/
│   ├── Manifest.json
│   └── Data/com.apple.CoreML/model.mlmodel
├── Service/
│   ├── CameraService.swift
│   └── PredictionService.swift
├── Feature/Scan/
│   ├── Model/
│   │   ├── AcneDetection.swift
│   │   └── PredictionResult.swift
│   ├── Utility/
│   │   ├── AcneLabelColor.swift
│   │   └── CoordinateTransformer.swift
│   ├── View/
│   │   ├── BoundingBoxView.swift
│   │   ├── CameraPreview.swift
│   │   ├── DetectionsOverlayView.swift
│   │   └── ScanView.swift
│   └── ViewModel/
│       └── ScanViewModel.swift
├── ContentView.swift
└── SuzuranApp.swift
```

## Penjelasan Folder Model

- `best.mlpackage` adalah model terbaru yang digunakan sebagai referensi utama untuk branch ini.
- `yolov26s_67_4.mlpackage` adalah aset model lama yang masih tersimpan di repository.
- Saat build, Xcode akan mengubah `.mlpackage` menjadi `.mlmodelc` di dalam bundle aplikasi.

## Penjelasan Folder Feature Scan

- `Model/` menyimpan model data hasil deteksi.
- `Utility/` menyimpan helper untuk warna label dan konversi koordinat bounding box.
- `View/` menyimpan tampilan kamera, overlay, dan hasil scan.
- `ViewModel/` menyimpan state dan alur logika scan.

## Prinsip Struktur

- Model ML dipisahkan dari logic UI.
- Kamera dan inference dipisah ke service agar lebih mudah diuji dan dirawat.
- UI hanya membaca state dari view model.
