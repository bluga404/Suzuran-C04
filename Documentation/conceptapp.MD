# Konsep Aplikasi

## Latar Belakang

Banyak orang yang sedang menjalani proses pemulihan jerawat merasa kesulitan mengetahui apakah kondisi kulit mereka benar-benar membaik. Perubahan yang terjadi sering kali berlangsung secara perlahan sehingga sulit disadari hanya dengan mengandalkan ingatan atau foto yang diambil secara tidak konsisten.

Di sisi lain, banyak pengguna mencoba berbagai produk skincare tanpa mengetahui apakah kandungan di dalamnya benar-benar sesuai dengan kondisi kulit mereka. Akibatnya, mereka sering merasa ragu apakah usaha yang dilakukan sudah berada di jalur yang tepat.

---

# Konsep Aplikasi

Aplikasi ini membantu pengguna memahami perkembangan kondisi jerawat mereka melalui proses scan wajah secara berkala. Setiap hasil scan akan dibandingkan dengan hasil sebelumnya sehingga pengguna dapat melihat perubahan kondisi kulit dari waktu ke waktu.

Selain itu, aplikasi juga membantu pengguna mengevaluasi skincare yang digunakan dengan memberikan informasi mengenai kecocokan kandungan produk terhadap kondisi jerawat mereka saat ini.

---

# Tujuan Aplikasi

Aplikasi ini dirancang untuk membantu pengguna:

- Mengetahui kondisi kulit wajah terbaru.
- Melihat perkembangan kondisi kulit dari waktu ke waktu.
- Mengevaluasi apakah program recovery yang sedang dijalankan memberikan hasil.
- Mengetahui apakah kandungan skincare yang digunakan sesuai dengan kondisi jerawat saat ini.
- Membantu pengguna merasa lebih yakin dan percaya diri selama proses pemulihan jerawat.

---

# Alur Pengguna

```text
Onboarding
      │
      ▼
Scan Wajah Pertama
      │
      ▼
(Tambahkan Skincare yang Digunakan)
      │
      ▼
Homepage
      │
      ├──────────────┐
      ▼              ▼
Scan Baru      Kelola Skincare
      │              │
      ▼              ▼
Hasil Scan    Analisis Kandungan
      │
      ▼
Laporan Perkembangan
```

---

# 1. Onboarding

## Tujuan

Mengumpulkan informasi awal yang diperlukan sebelum pengguna mulai menggunakan aplikasi.

## Aktivitas Pengguna

- Melakukan scan wajah pertama.
- Menambahkan skincare yang sedang digunakan (opsional).

Setelah selesai, pengguna akan diarahkan ke halaman Beranda.

---

# 2. Beranda (Homepage)

## Tujuan

Membantu pengguna mengetahui kondisi kulitnya secara cepat tanpa harus membuka laporan secara lengkap.

## Informasi yang Ditampilkan

### Kondisi Kulit Saat Ini

- Foto hasil scan terakhir (atau visualisasi wajah).
- Skin Score terbaru.
- Kategori kondisi kulit.
- Tanggal terakhir melakukan scan.

### Perkembangan

Perbandingan dengan hasil scan sebelumnya.

Contoh:

- Skin Score meningkat 4% dibandingkan scan sebelumnya.
- Skin Score menurun 2% dibandingkan scan sebelumnya.

### Grafik Perkembangan

Menampilkan perubahan:

- Skin Score.
- Jumlah total jerawat.

### Ringkasan Skincare

Memberikan insight singkat, misalnya:

- Beberapa kandungan skincare mungkin kurang sesuai dengan kondisi kulit saat ini.
- Skincare yang digunakan saat ini sesuai dengan kondisi kulit.

### Aksi Utama

- Mulai Scan Baru.
- Lihat Laporan.
- Kelola Skincare.

---

# 3. Scan Wajah

## Tujuan

Mengambil foto wajah dengan posisi yang konsisten sehingga hasil analisis lebih akurat.

## Halaman Pengambilan Foto

### Yang Ditampilkan

- Panduan posisi wajah.
- Indikator pencahayaan.
- Indikator jarak kamera.
- Petunjuk posisi kepala.

Contoh petunjuk:

- Geser wajah sedikit ke belakang.
- Dekatkan wajah.
- Turunkan posisi ponsel.
- Hadapkan wajah lurus ke depan.
- Cahaya sudah cukup.

Apabila seluruh indikator terpenuhi, aplikasi akan mengambil foto secara otomatis.

### Data yang Disimpan

Foto dari beberapa area wajah:

- Wajah keseluruhan.
- Dahi.
- Pipi kanan.
- Pipi kiri.
- Hidung.
- Dagu.

Beserta:

- Tanggal dan waktu scan.

---

# 4. Review Hasil Scan

## Tujuan

Memberikan kesempatan kepada pengguna untuk memastikan hasil foto sebelum disimpan.

## Yang Ditampilkan

- Seluruh foto hasil scan.
- Foto dikelompokkan berdasarkan area wajah.

Untuk setiap area ditampilkan:

- Jumlah jerawat.
- Jenis jerawat yang terdeteksi.

Jenis jerawat:

- Komedo
- Papula
- Pustula
- Nodul
- Kista

Setelah pengguna menyimpan hasil scan, aplikasi akan menghasilkan Skin Score.

---

# 5. Hasil Scan

## Tujuan

Membantu pengguna memahami kondisi kulit berdasarkan hasil analisis terbaru.

## Yang Ditampilkan

### Skin Score

Menampilkan nilai kondisi kulit beserta kategorinya.

Contoh:

- Skin Score: 74
- Kategori: Jerawat Sedang

### Ringkasan Jerawat

- Jumlah total jerawat.
- Jumlah setiap jenis jerawat.
- Persebaran jerawat pada wajah.

### Persebaran Jerawat

Visualisasi lokasi munculnya jerawat pada setiap area wajah.

### Insight

Contoh:

- Jerawat meradang paling banyak berada di pipi kanan.
- Kondisi dahi menunjukkan perbaikan dibandingkan scan sebelumnya.

---

# 6. Halaman Skincare

## Tujuan

Membantu pengguna memahami apakah skincare yang digunakan sesuai dengan kondisi kulitnya.

## Fitur

### Skincare Saat Ini

Pengguna dapat menambahkan produk seperti:

- Facial Wash
- Moisturizer
- Sunscreen
- Serum
- Obat jerawat

### Riwayat Skincare

Menampilkan daftar produk yang pernah digunakan sebelumnya.

### Analisis Kandungan

Aplikasi akan membaca kandungan dari setiap produk, kemudian membandingkannya dengan kondisi jerawat pengguna.

Contoh hasil:

- Niacinamide → Sesuai.
- Isopropyl Myristate → Berpotensi menyumbat pori.

### Ringkasan

Contoh:

> Ditemukan dua kandungan dalam skincare Anda yang mungkin kurang sesuai dengan kondisi kulit saat ini.

---

# 7. Laporan Perkembangan

## Tujuan

Membantu pengguna mengevaluasi perkembangan kondisi kulit secara menyeluruh.

## Yang Ditampilkan

### Trend Perkembangan

- Skin Score.
- Jumlah total jerawat.
- Perubahan setiap jenis jerawat.

### Perbandingan Area Wajah

Membandingkan kondisi awal dengan kondisi terbaru pada:

- Dahi.
- Pipi kanan.
- Pipi kiri.
- Hidung.
- Dagu.

Contoh:

- Dahi membaik 35%.
- Pipi kanan membaik 18%.

### Perbandingan Foto

Menampilkan foto pertama dan foto terbaru secara berdampingan.

### Insight

Contoh:

- Area dengan perbaikan paling besar adalah dahi.
- Papula berkurang sebanyak 45%.
- Jerawat meradang masih paling banyak muncul di pipi kanan.

### Kategori Kondisi Kulit

Berdasarkan Skin Score terbaru, misalnya:

- Sangat Ringan
- Ringan
- Sedang
- Berat
- Sangat Berat

---

# Manfaat yang Diharapkan

Melalui aplikasi ini, pengguna diharapkan dapat:

- Lebih memahami kondisi kulitnya saat ini.
- Melihat perkembangan pemulihan secara objektif berdasarkan data.
- Mengevaluasi apakah skincare yang digunakan sudah sesuai.
- Lebih percaya diri selama menjalani proses recovery karena dapat melihat perubahan yang terjadi dari waktu ke waktu.