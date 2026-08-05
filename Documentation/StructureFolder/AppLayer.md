## App Layer

### File: Suzuran/SuzuranApp.swift
Peran:
- Titik masuk aplikasi iOS.
- Membuat container global satu kali.
- Menyuntikkan RootViewModel dan dependency ke RootView.

Cuplikan kunci:
~~~swift
@StateObject private var container = AppContainer.live()
~~~
Arti:
- StateObject menjaga AppContainer hidup selama lifecycle App.
- Semua dependency utama dipusatkan dari sini agar mudah dilacak.

Cuplikan kunci:
~~~swift
RootView(viewModel: container.rootViewModel, dependencies: container.makeRootViewDependencies())
~~~
Arti:
- RootView tidak membangun dependency sendiri.
- RootView menerima objek yang sudah dirakit (dependency injection).

---

### File: Suzuran/App/AppContainer.swift
Peran:
- Composition Root utama.
- Merakit logger, key-value store, environment, bootstrapper, root view model.
- Menyediakan factory untuk kebutuhan RootView (misalnya HomeViewModel).

Cuplikan kunci:
~~~swift
let environment = AppEnvironment(logger: logger, keyValueStore: keyValueStore)
~~~
Arti:
- Resource global dibungkus ke AppEnvironment.
- Mudah mengganti implementasi (misal logger lain) tanpa ubah banyak file.

Cuplikan kunci:
~~~swift
let rootViewModel = RootViewModel(bootstrapper: bootstrapper)
~~~
Arti:
- RootViewModel tidak tahu cara membuat bootstrapper.
- RootViewModel hanya menerima kontrak siap pakai.

Cuplikan kunci:
~~~swift
func makeHomeViewModel() -> HomeViewModel
~~~
Arti:
- Pembuatan ViewModel dipusatkan agar konsisten dan testable.

---

### File: Suzuran/App/AppEnvironment.swift
Peran:
- Menyimpan dependency global sederhana.
- Saat ini: logger dan keyValueStore.

Cuplikan kunci:
~~~swift
let logger: AppLogging
~~~
Arti:
- Menggunakan protokol AppLogging, bukan langsung AppLogger.
- Mudah di-mock pada testing.

---

### File: Suzuran/App/AppBootstrapper.swift
Peran:
- Menjalankan proses startup awal.
- Menulis flag first-launch.
- Mencatat log startup.

Cuplikan kunci:
~~~swift
let hasLaunchedBefore = environment.keyValueStore.bool(forKey: AppConstants.hasLaunchedBeforeKey)
~~~
Arti:
- Startup status disimpan di persistence agar tidak perlu setup berulang.

Cuplikan kunci:
~~~swift
if !hasLaunchedBefore { environment.keyValueStore.set(true, forKey: AppConstants.hasLaunchedBeforeKey) }
~~~
Arti:
- Logika first run sangat sederhana dan terisolasi.

---

### File: Suzuran/App/Root/RootViewModel.swift
Peran:
- Mengelola fase startup aplikasi.
- Menjembatani bootstrap async ke state UI.

Istilah penting:
- Phase: representasi tahapan state layar root.
- ObservableObject: objek yang bisa mem-publish perubahan ke View.

Cuplikan kunci:
~~~swift
enum Phase: Equatable { case launching; case ready; case failed(AppError) }
~~~
Arti:
- UI root cukup membaca satu state terpusat.

Cuplikan kunci:
~~~swift
try await bootstrapper.bootstrap()
~~~
Arti:
- Startup dijalankan async tanpa blok main thread.

Cuplikan kunci:
~~~swift
phase = .failed(AppErrorMapper.map(error))
~~~
Arti:
- Semua error dipetakan ke bentuk AppError yang konsisten.

---

### File: Suzuran/App/Root/RootView.swift
Peran:
- Entry screen berbasis state dari RootViewModel.
- Menjadi host NavigationStack.
- Menyimpan router dan homeViewModel sebagai StateObject.

Cuplikan kunci:
~~~swift
NavigationStack(path: $router.path)
~~~
Arti:
- Navigasi berbasis data path, bukan imperative push controller.

Cuplikan kunci:
~~~swift
case .ready: HomeView(viewModel: homeViewModel, onNavigateToIngredientOcr: { router.push(.ingredientOcr) })
~~~
Arti:
- HomeView tidak tahu detail router.
- Closure navigasi membuat coupling lebih rendah.

Cuplikan kunci:
~~~swift
.navigationDestination(for: AppRoute.self)
~~~
Arti:
- Satu tempat untuk memetakan route ke tujuan layar.

---

### File: Suzuran/App/Navigation/AppRoute.swift
Peran:
- Daftar rute aplikasi tingkat root.

Cuplikan kunci:
~~~swift
enum AppRoute: Hashable { case ingredientOcr }
~~~
Arti:
- Route harus Hashable agar bisa dipakai di path NavigationStack.

---

### File: Suzuran/App/Navigation/AppRouter.swift
Peran:
- Pengelola path navigasi yang bisa dipantau UI.

Cuplikan kunci:
~~~swift
@Published var path: [AppRoute] = []
~~~
Arti:
- Setiap perubahan path langsung merender perubahan navigasi.

Cuplikan kunci:
~~~swift
func push(_ route: AppRoute) { path.append(route) }
~~~
Arti:
- API router sederhana dan mudah dipanggil dari closure UI.
