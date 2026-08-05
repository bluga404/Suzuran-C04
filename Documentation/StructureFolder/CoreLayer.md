## 2.2 Core Layer

## 2.2.1 Error Handling

### File: Suzuran/Core/Error/AppError.swift
Peran:
- Error type standar aplikasi lintas layer.
- Menyediakan userMessage untuk UI.

Cuplikan kunci:
~~~swift
case networkUnavailable
~~~
Arti:
- Error domain transport dipisahkan jelas untuk penanganan UI.

Cuplikan kunci:
~~~swift
var userMessage: String
~~~
Arti:
- UI tidak perlu merakit pesan error sendiri.

### File: Suzuran/Core/Error/AppErrorMapper.swift
Peran:
- Adapter error umum ke AppError.

Cuplikan kunci:
~~~swift
if let urlError = error as? URLError { ... }
~~~
Arti:
- Error URLSession dipetakan ke kategori yang lebih manusiawi.

## 2.2.2 Logging

### File: Suzuran/Core/Logging/AppLogger.swift
Peran:
- Kontrak logging AppLogging + implementasi AppLogger.

Cuplikan kunci:
~~~swift
func info(_ message: String, file: String = #fileID, line: Int = #line)
~~~
Arti:
- Lokasi file dan baris dicatat otomatis tanpa menulis manual.

Cuplikan kunci:
~~~swift
#if DEBUG
print("[\(timestamp)] [\(level)] \(file):\(line) - \(message)")
#endif
~~~
Arti:
- Logging aktif hanya di debug agar production lebih bersih.

Kenapa dipakai di AppEnvironment:
- Karena logger dibutuhkan lintas fitur dan startup.
- Menaruh logger di environment memudahkan injeksi dan penggantian implementasi.

## 2.2.3 Foundation dan State

### File: Suzuran/Core/Foundation/AppConstants.swift
Peran:
- Konstanta global.

Cuplikan kunci:
~~~swift
static let hasLaunchedBeforeKey = "app.hasLaunchedBefore"
~~~
Arti:
- Key persistence dipusatkan agar tidak typo di banyak file.

### File: Suzuran/Core/State/LoadableState.swift
Peran:
- Generic state machine reusable untuk layar data.

Cuplikan kunci:
~~~swift
enum LoadableState<Value: Equatable>: Equatable
~~~
Arti:
- Menghindari state loading/error/empty yang berulang di tiap ViewModel.

## 2.2.4 Design System

### Tokens
- Suzuran/Core/DesignSystem/Tokens/AppColor.swift
- Suzuran/Core/DesignSystem/Tokens/AppTypography.swift
- Suzuran/Core/DesignSystem/Tokens/AppSpacing.swift
- Suzuran/Core/DesignSystem/Tokens/AppCornerRadius.swift

Peran:
- Sumber tunggal visual styling.

Cuplikan kunci:
~~~swift
static let title = Font.custom("AvenirNext-DemiBold", size: 28)
~~~
Arti:
- Font konsisten di seluruh aplikasi.

### Modifier
- Suzuran/Core/DesignSystem/Modifiers/ScreenContainerModifier.swift

Cuplikan kunci:
~~~swift
func appScreenContainer() -> some View
~~~
Arti:
- Setiap screen bisa memakai style container yang sama.

### Components
- Suzuran/Core/DesignSystem/Components/AppCard.swift
- Suzuran/Core/DesignSystem/Components/AppTextField.swift
- Suzuran/Core/DesignSystem/Components/PrimaryButton.swift

Peran:
- Komponen UI reusable.

Cuplikan kunci:
~~~swift
struct AppCard<Content: View>: View
~~~
Arti:
- Reusability tinggi untuk card content generik.

### State Views
- LoadingStateView.swift
- ErrorStateView.swift
- EmptyStateView.swift
- OfflineStateView.swift
- PermissionStateView.swift

Peran:
- Pattern tampilan state yang konsisten lintas layar.