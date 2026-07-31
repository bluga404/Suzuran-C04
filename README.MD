## Tech Proof LLM in App

Tech proof ini mengeksplorasi integrasi LLM `gemini-2.5-flash` ke dalam iOS app.

### Tech Stack

- Firebase account
- Firebase SDK
- Firebase AI Logic

### Alasan Menggunakan Firebase

Firebase dipakai supaya akses ke Gemini bisa dilakukan lewat Firebase AI Logic, sehingga:

- API key tidak perlu ditulis langsung di source code
- konfigurasi akses bisa dikelola dari Firebase project
- request ke Gemini bisa diamankan dengan App Check

### Catatan Penting Saat Implementasi

- Pastikan `bundle ID` di Xcode sama persis dengan app yang didaftarkan di Firebase
- Pastikan file `GoogleService-Info.plist` sudah masuk ke target aplikasi yang benar
- Jika memakai simulator, aktifkan App Check debug provider sebelum `FirebaseApp.configure()`
- Setelah app dijalankan, ambil `debug token` dari console Xcode lalu register ke Firebase Console
- Kalau App Check masih `Unregistered`, request ke Gemini bisa gagal dengan error generik seperti `FirebaseAILogic.GenerateContentError error 0`
- Untuk production di device fisik, gunakan provider App Check yang sesuai:
  - `App Attest` untuk iOS modern
  - `DeviceCheck` sebagai opsi Apple provider lain sesuai kebutuhan project
- Pastikan API yang dibutuhkan oleh Firebase AI Logic sudah aktif di Firebase project

### Troubleshooting Ringkas

Kalau muncul error saat kirim prompt ke Gemini:
1. Cek apakah App Check sudah di-set up untuk app ini
2. Cek apakah app masih `Unregistered` di Firebase Console
3. Cek apakah debug token sudah didaftarkan untuk simulator
4. Cek apakah model yang dipakai valid, misalnya `gemini-2.5-flash`
5. Cek console Xcode untuk pesan error yang lebih detail
