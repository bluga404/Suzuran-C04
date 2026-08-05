# Referensi Penelitian

Dasar proyek ini disesuaikan dengan referensi di bawah. Tujuannya agar desain arsitektur dan penggunaan SwiftUI mengikuti praktik yang dapat dipertanggungjawabkan.

## Referensi Resmi Apple dan Swift

1. Siklus hidup aplikasi SwiftUI (`App` protocol):
   https://developer.apple.com/documentation/swiftui/app

2. SwiftUI `NavigationStack` dan navigasi berbasis path:
   https://developer.apple.com/documentation/swiftui/navigationstack

3. SwiftUI `@StateObject`:
   https://developer.apple.com/documentation/swiftui/stateobject

4. SwiftUI `@ObservedObject`:
   https://developer.apple.com/documentation/swiftui/observedobject

5. Mengelola data model dalam aplikasi (`source-of-truth`):
   https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app

6. Human Interface Guidelines untuk launching:
   https://developer.apple.com/design/human-interface-guidelines/launching

7. Panduan launch screen Xcode:
   https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen

8. Swift API Design Guidelines (penamaan dan dokumentasi):
   https://www.swift.org/documentation/api-design-guidelines/

9. Referensi markup Xcode untuk komentar kode dan Quick Help:
   https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/

## Referensi Praktis Arsitektur

1. Clean Architecture untuk SwiftUI (konsep pemisahan lapisan dan arah dependensi):
   https://nalexn.github.io/clean-architecture-swiftui/

2. Dependency Injection di Swift dengan protocol (ide komposisi dan factory):
   https://swiftwithmajid.com/2019/03/06/dependency-injection-in-swift-with-protocols/

## Pelajaran Penting yang Digunakan di Proyek Ini

- Gunakan satu composition root untuk membangun dependensi.
- Buat view model fitur di composition, bukan di view model lifecycle root.
- Jaga kontrak domain tetap bebas dari detail framework.
- Map DTO ke entitas domain sebelum mencapai presentasi.
- Jadikan pengalaman startup langsung dan dikelola oleh sistem.
- Gunakan `@StateObject` untuk ownership dan `@ObservedObject` untuk dependency yang diinject.
- Gunakan disiplin penamaan dan dokumentasi yang kuat agar tim scale tetap terjaga.
