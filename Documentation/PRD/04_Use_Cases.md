# 4. Use Case Feature

Bagian ini menjelaskan cara user memakai feature scan pada aplikasi.

## Use Case 1 - Scan Langsung Dengan Kamera

### Tujuan

User ingin mendeteksi jenis acne langsung dari kamera.

### Alur

1. User membuka feature scan.
2. User menekan tombol `Scan`.
3. Aplikasi meminta izin kamera jika belum ada.
4. Kamera aktif dalam mode live preview.
5. User mengambil foto.
6. Foto diproses oleh model.
7. Hasil deteksi ditampilkan di halaman result.

### Output

- Nama acne type.
- Confidence score.
- Bounding box pada area yang terdeteksi.

## Use Case 2 - Upload Foto Dari Galeri

### Tujuan

User ingin menganalisis foto lama tanpa memakai kamera.

### Alur

1. User membuka feature scan.
2. User menekan `Upload Image`.
3. User memilih foto dari galeri.
4. Aplikasi mengubah data gambar menjadi `UIImage`.
5. Foto diproses oleh model.
6. Hasil tampil seperti skenario kamera.

### Output

- Hasil prediksi acne type.
- Daftar deteksi pada gambar.
- Overlay bounding box.

## Use Case 3 - Ganti Kamera

### Tujuan

User ingin memakai kamera depan atau belakang sesuai kebutuhan.

### Alur

1. User masuk ke mode kamera.
2. User menekan tombol switch camera.
3. `CameraService` memindahkan input device.
4. Preview kamera berubah ke kamera yang dipilih.

### Output

- Kamera aktif berganti tanpa keluar dari feature.

## Use Case 4 - Melihat Detail Hasil Deteksi

### Tujuan

User ingin membaca hasil prediksi yang paling relevan.

### Alur

1. Setelah inference selesai, aplikasi menampilkan result page.
2. User melihat top prediction sebagai ringkasan utama.
3. Jika ada banyak bounding box, user bisa melihat daftar semua deteksi.
4. User dapat tap bounding box untuk melihat confidence detail.

### Output

- Ringkasan top prediction.
- List semua deteksi.
- Confidence per item.

## Use Case 5 - Penanganan Kondisi Error

### Skenario

- Permission kamera ditolak.
- Gambar gagal dimuat dari galeri.
- Model gagal dimuat.
- Output model tidak sesuai format yang diharapkan.

### Output

- Aplikasi menampilkan pesan error yang jelas.
- User tetap bisa retry scan atau upload ulang gambar.

## Definisi Selesai

Feature dianggap berhasil bila:

- User bisa scan atau upload foto.
- Model memberi label class yang benar.
- Bounding box tampil di gambar.
- Hasil bisa dibaca tanpa langkah tambahan.
