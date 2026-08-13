# Project Setup & Build

## Persyaratan

| Item | Minimum |
|------|---------|
| macOS | 15.0+ (Sequoia) |
| Xcode | 26.0+ |
| iOS Target | 26.0 |
| Swift | 6.0 |
| Device | iPhone (Portrait only) |

## Clone & Buka Project

```bash
git clone https://github.com/bluga404/Suzuran-C04.git
cd Suzuran-C04
open Suzuran.xcodeproj
```

## Build

1. Pilih scheme **Suzuran**
2. Pilih target device/simulator (iPhone 17 Pro recommended)
3. `Cmd + B` untuk build
4. `Cmd + R` untuk run

## Struktur Xcode Project

Project menggunakan **PBXFileSystemSynchronizedRootGroup** — ini berarti Xcode otomatis mendeteksi semua file dalam folder `Suzuran/`. Tidak perlu drag-and-drop file ke Xcode navigator.

**Implikasi:**
- Buat file baru langsung di Finder atau terminal — Xcode otomatis include
- Hapus file langsung — Xcode otomatis remove dari build
- Tidak perlu edit `.pbxproj` untuk menambah/menghapus file

## ML Model

Model CoreML ada di `Suzuran/Infrastructure/ML/v26_fp16.mlpackage`. Xcode otomatis generate Swift class `v26_fp16` dari model ini.

**Jangan:**
- Memindahkan model ke folder lain tanpa update reference
- Mengcommit model weight baru tanpa diskusi tim (file besar)

## Info.plist Keys

```xml
<key>NSCameraUsageDescription</key>
<string>Suzuran membutuhkan akses kamera untuk memindai wajah dan mendeteksi jerawat.</string>
```

Tambahkan key baru di `Info.plist` jika fitur baru membutuhkan permission (lokasi, foto, dll).

## Git Workflow

Lihat `README.MD` untuk branching strategy dan commit conventions.

**Quick reference:**
```bash
# Buat branch fitur baru
git checkout -b feature/nama-fitur

# Commit
git add .
git commit -m "feat(scope): deskripsi perubahan"

# Push
git push -u origin feature/nama-fitur
```

## Testing

Test files ada di `SuzuranTests/`. Saat ini menggunakan:
- **XCTest** untuk property-based tests
- **Swift Testing** (`@Suite`, `@Test`, `#expect`) untuk unit tests baru

```bash
# Run tests via command line
xcodebuild test -project Suzuran.xcodeproj -scheme Suzuran -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Troubleshooting

### "Multiple commands produce" error
→ `Product > Clean Build Folder` (⇧⌘K), then rebuild

### Model class not found
→ Build once first — Xcode generates Swift class from `.mlpackage` during build

### Camera not working on Simulator
→ Camera membutuhkan device fisik. Gunakan device untuk testing fitur scan.
