# Suzuran — C04

Suzuran adalah aplikasi yang membantu pengguna mengevaluasi perkembangan pemulihan jerawat secara lebih mandiri melalui perbandingan hasil scan, tren skin score, dan pencatatan skincare.

---

## About the Project

### Big Idea

**Insecurity**

### Keyword

**Lack of Confidence**

### Essential Question

> How might we help people with insecurity develop self-love?

### Challenge Response

> An app to support people who lack confidence because of their acne in independently evaluating their recovery progress by comparing side-by-side scan results, regularly tracking skin score trends, and identifying skincare ingredients used throughout their recovery journey.

Suzuran dirancang sebagai alat bantu evaluasi, bukan sebagai pengganti diagnosis atau konsultasi medis. Aplikasi membantu pengguna melihat perubahan kondisi jerawat secara lebih terstruktur melalui:

- Side-by-side scan comparison
- Overall skin score
- Skin score berdasarkan area wajah
- Acne type detection
- Skin score trend
- Skincare routine tracking
- Skincare product and ingredient logging
- Weekly recovery evaluation

---

## Branching Strategy

Repository ini menggunakan enam jenis branch utama.

| Branch | Tujuan |
|---|---|
| `main` | Branch utama yang berisi versi stabil dan siap untuk production atau deployment |
| `development` | Branch integrasi untuk fitur yang sudah siap diuji |
| `feature/<branch-name>` | Pengembangan fitur aplikasi |
| `ML/<branch-name>` | Eksperimen, model training, dataset, dan pekerjaan Machine Learning |
| `Design/<branch-name>` | Design exploration, UI/UX assets, dan design documentation |
| `Tech/<branch-name>` | Technical proof, infrastructure, research, dan technical backlog |

### Branch Naming Examples

```text
main
development
feature/weekly-scan
feature/skincare-routine
ML/testing-yolo26
ML/coreml-export
Design/onboarding-flow
Design/scan-result-screen
Tech/camera-integration
Tech/local-storage
```

Gunakan nama branch yang:

- Singkat dan deskriptif
- Menggunakan huruf kecil setelah prefix
- Menggunakan tanda hubung `-` sebagai pemisah kata
- Menjelaskan pekerjaan yang sedang dilakukan

---

## Recommended Merge Flow

Alur perubahan yang direkomendasikan:

```text
ML/<branch-name>
Design/<branch-name>
Tech/<branch-name>
feature/<branch-name>
        │
        ▼
development
        │
        ▼
main
```

Penjelasan:

1. Eksperimen dan pekerjaan divisi dilakukan pada branch `ML/`, `Design/`, atau `Tech/`.
2. Pengembangan fitur aplikasi dilakukan pada branch `feature/`.
3. Fitur yang sudah siap diuji dibuatkan Pull Request menuju `development`.
4. Perubahan yang sudah stabil dan siap deployment dibuatkan Pull Request dari `development` menuju `main`.

---

## Repository Rules

### 1. Do Not Force Push to `main`

Dilarang melakukan force push langsung ke branch `main`.

Jangan menjalankan:

```bash
git push --force origin main
```

atau:

```bash
git push -f origin main
```

Perubahan yang ingin dimasukkan ke `main` harus melalui salah satu cara berikut:

- Membuat Pull Request
- Melakukan review bersama anggota kelompok
- Mengabari anggota kelompok sebelum proses merge

---

### 2. Work in the Appropriate Branch

Gunakan branch berdasarkan jenis pekerjaan:

| Pekerjaan | Branch |
|---|---|
| Machine Learning experiment | `ML/<branch-name>` |
| Design exploration | `Design/<branch-name>` |
| Technical proof | `Tech/<branch-name>` |
| Application feature development | `feature/<branch-name>` |
| Integration and testing | `development` |
| Production and deployment | `main` |

Jangan menggunakan `main` untuk eksperimen, tech proof, design exploration, atau pekerjaan yang belum siap digunakan.

---

### 3. Delete Unused Branches

Hapus branch yang:

- Sudah selesai dan telah di-merge
- Sudah tidak digunakan
- Dibuat untuk eksperimen sementara
- Sudah digantikan oleh branch lain

Menghapus branch lokal:

```bash
git branch -d nama-branch
```

Gunakan force delete hanya jika branch memang tidak lagi diperlukan:

```bash
git branch -D nama-branch
```

Menghapus branch remote:

```bash
git push origin --delete nama-branch
```

Contoh:

```bash
git branch -d ML/testing-yolo26
git push origin --delete ML/testing-yolo26
```

---

### 4. Use Conventional Commits

Gunakan format commit message dari [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

Format dasar:

```text
<type>[optional scope]: <description>
```

Contoh:

```text
feat(scan): add side-by-side scan comparison
fix(camera): resolve incorrect camera orientation
docs(readme): add repository contribution rules
refactor(ml): simplify inference pipeline
test(ml): add validation for acne detection model
chore(design): organize design assets
```

Jenis commit yang umum digunakan:

| Type | Penggunaan |
|---|---|
| `feat` | Menambahkan fitur baru |
| `fix` | Memperbaiki bug |
| `docs` | Memperbarui dokumentasi |
| `refactor` | Mengubah struktur kode tanpa mengubah perilaku utama |
| `test` | Menambahkan atau memperbarui testing |
| `chore` | Maintenance atau pekerjaan pendukung |
| `perf` | Meningkatkan performa |
| `build` | Perubahan build system atau dependency |
| `ci` | Perubahan workflow CI/CD |
| `style` | Perubahan format yang tidak memengaruhi logika |

Hindari commit message yang tidak menjelaskan perubahan:

```text
update
fix
done
revisi
perubahan baru
coba lagi
```

Gunakan pesan yang lebih jelas:

```text
fix(ml): correct acne class mapping
feat(routine): add morning skincare reminder
docs(readme): update branch naming convention
```

---

## Getting Started

### Option A — Clone Repository

Cara yang direkomendasikan untuk mengambil repository ke komputer lokal:

```bash
git clone https://github.com/bluga404/Suzuran-C04.git
```

Masuk ke folder repository:

```bash
cd Suzuran-C04
```

Periksa remote repository:

```bash
git remote -v
```

---

### Option B — Connect an Existing Local Project

Gunakan cara ini jika project sudah tersedia di komputer lokal tetapi belum terhubung ke GitHub.

Masuk ke folder project:

```bash
cd "path/menuju/project"
```

Inisialisasi Git:

```bash
git init
```

Tambahkan remote repository dengan nama `origin`:

```bash
git remote add origin https://github.com/bluga404/Suzuran-C04.git
```

Periksa remote:

```bash
git remote -v
```

Ambil informasi branch dari remote:

```bash
git fetch origin
```

---

## Check Current Branch

Sebelum melakukan perubahan, selalu cek branch yang sedang aktif:

```bash
git status
```

Alternatif:

```bash
git branch --show-current
```

Untuk melihat semua branch lokal:

```bash
git branch
```

Untuk melihat branch lokal dan remote:

```bash
git branch -a
```

---

## Create a New Branch

Format:

```bash
git checkout -b "nama-branch-baru"
```

Contoh untuk Machine Learning:

```bash
git checkout -b ML/testing-yolo26
```

Contoh untuk Design:

```bash
git checkout -b Design/scan-result-screen
```

Contoh untuk Tech:

```bash
git checkout -b Tech/coreml-integration
```

Contoh untuk fitur:

```bash
git checkout -b feature/weekly-scan
```

Periksa kembali branch aktif:

```bash
git status
```

---

## Add Changes

Menambahkan file tertentu:

```bash
git add "nama-file"
```

Contoh:

```bash
git add README.md
```

Menambahkan beberapa file:

```bash
git add file-pertama file-kedua
```

Menambahkan seluruh perubahan:

```bash
git add .
```

Periksa file yang akan di-commit:

```bash
git status
```

---

## Commit Changes

Gunakan format Conventional Commits:

```bash
git commit -m "type(scope): description"
```

Contoh:

```bash
git commit -m "feat(scan): add weekly scan comparison"
```

```bash
git commit -m "fix(ml): correct YOLO class mapping"
```

```bash
git commit -m "docs(readme): add branch workflow"
```

---

## Push a New Branch

Format:

```bash
git push -u origin "nama-branch"
```

Contoh:

```bash
git push -u origin ML/testing-yolo26
```

Parameter `-u` menghubungkan branch lokal dengan branch remote. Setelah push pertama, push berikutnya cukup menggunakan:

```bash
git push
```

---

## Complete Workflow Example

Contoh workflow untuk mengembangkan model YOLO26:

```bash
# Periksa branch aktif
git status

# Buat branch baru
git checkout -b ML/testing-yolo26

# Periksa perubahan
git status

# Tambahkan file
git add .

# Commit perubahan
git commit -m "feat(ml): add YOLO26 training experiment"

# Push branch ke GitHub
git push -u origin ML/testing-yolo26
```

Setelah branch berhasil di-push:

1. Buka repository GitHub.
2. Buat Pull Request.
3. Pilih target branch yang sesuai.
4. Minta anggota kelompok melakukan review.
5. Merge setelah perubahan disetujui.
6. Hapus branch jika sudah tidak digunakan.

---

## Before You Push

Pastikan melakukan pemeriksaan berikut:

- [ ] Tidak melakukan perubahan langsung di `main / development`
- [ ] Tidak ada file rahasia atau credential (termasuk API key dan lainnya)
- [ ] Tidak ada dataset berukuran besar yang tidak diperlukan
- [ ] Tidak ada model weight besar yang tidak sengaja ikut di-commit
- [ ] Commit message mengikuti Conventional Commits
- [ ] Perubahan sudah diuji
- [ ] `git status` sudah diperiksa
- [ ] Pull Request diarahkan ke branch yang benar

---

## Important Alert

> [!WARNING]
> Kalau masih bingung, silakan saling bertanya. Bertanya tidak akan membuat dunia kiamat, tetapi salah push yang menyebabkan conflict rasanya seperti kiamat.

---

## References

- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Git Documentation](https://git-scm.com/docs)
