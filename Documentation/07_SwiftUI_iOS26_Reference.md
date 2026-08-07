# SwiftUI & iOS 26 Quick Reference

Referensi cepat API dan pattern yang digunakan di project ini. Untuk detail lengkap, lihat dokumentasi Apple:

- **HIG**: https://developer.apple.com/design/human-interface-guidelines/
- **SwiftUI**: https://developer.apple.com/documentation/swiftui
- **WWDC25 — Liquid Glass**: https://developer.apple.com/videos/play/wwdc2025/219/
- **WWDC25 — New SwiftUI**: https://developer.apple.com/videos/play/wwdc2025/256/
- **WWDC25 — Build with New Design**: https://developer.apple.com/videos/play/wwdc2025/323/
- **SF Symbols**: https://developer.apple.com/sf-symbols/

---

## Navigation (iOS 26 Style)

```swift
NavigationStack {
    ContentView()
        .navigationTitle("Judul")
        .toolbarTitleDisplayMode(.inline)    // Title di toolbar row
        .toolbarRole(.editor)               // Left-align title
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { } label: { Image(systemName: "plus") }
                    .buttonStyle(.glassProminent)
            }
        }
}
```

## Toolbar Placements

| Placement | Posisi |
|-----------|--------|
| `.title` | Title area (inline mode) |
| `.topBarLeading` | Kiri navigation bar |
| `.topBarTrailing` | Kanan navigation bar |
| `.navigation` | Close/back di modal |
| `.primaryAction` | Primary action slot |
| `.bottomBar` | Bottom toolbar |

## Modal/Sheet Pattern

```swift
.sheet(isPresented: $showForm) {
    NavigationStack {
        FormView()
            .navigationTitle("Judul")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(role: .close) { dismiss() }    // Auto X icon
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .confirm) { save() }     // Auto checkmark
                }
            }
            .interactiveDismissDisabled(hasChanges)
    }
}
```

## Liquid Glass — Kapan Pakai

| Skenario | Pendekatan |
|----------|-----------|
| NavigationBar, TabBar, Toolbar | **Otomatis** — jangan style manual |
| Floating action button | `.buttonStyle(.glassProminent)` |
| Custom floating element | `.glassEffect(.regular.interactive())` — **modifier terakhir** |
| Card background | `.regularMaterial` — BUKAN `.glassEffect()` |
| Multiple glass elements | Wrap dalam `GlassEffectContainer { }` |

**Yang TIDAK boleh:**
- `.glassEffect()` pada List rows atau form content
- `.background(.ultraThinMaterial).glassEffect()` (double material)
- Override `toolbarBackground` di iOS 26
- Glass di content layer (hanya untuk navigation/floating layer)

## Scroll APIs

```swift
ScrollView {
    content
}
.scrollEdgeEffectStyle(.soft, for: .top)      // Smooth edge fade
.contentMargins(.bottom, 30, for: .scrollContent)
.scrollDismissesKeyboard(.immediately)
```

## TabView (iOS 26)

```swift
TabView {
    Tab("Home", systemImage: "house.fill") { HomeView() }
    Tab("Scan", systemImage: "face.dashed") { ScanView() }
    Tab(role: .search) { SearchView() }       // Built-in search tab
}
.tabViewStyle(.sidebarAdaptable)              // Tab → Sidebar di iPad
.tabBarMinimizeBehavior(.onScrollDown)        // Hide saat scroll
```

## Typography

| Style | Size | Weight | Gunakan untuk |
|-------|------|--------|---------------|
| `.largeTitle` | 34pt | Regular | Screen title |
| `.title` | 28pt | Regular | Section title |
| `.title3` | 20pt | Semibold | Prominent label |
| `.headline` | 17pt | Semibold | Row primary |
| `.body` | 17pt | Regular | Content text |
| `.subheadline` | 15pt | Regular | Secondary label |
| `.footnote` | 13pt | Regular | Small info |
| `.caption` | 12pt | Regular | Metadata |

```swift
// Font width (baru iOS 26)
Text("TITLE").fontWidth(.expanded)      // Lebih lebar, monumental
Text("label").fontWidth(.condensed)     // Lebih sempit, compact
```

## Colors

```swift
// Teks
.foregroundStyle(.primary)               // Teks utama
.foregroundStyle(.secondary)             // Teks pendukung

// Backgrounds
Color(.systemBackground)                 // Base
Color(.systemGroupedBackground)          // List/grouped

// Interactive
.tint(.accentColor)                      // System tint

// JANGAN gunakan:
.foregroundColor(.black)                 // ❌ Tidak adaptif
Color(hex: "...")                        // ❌ Hardcode
```

## SF Symbols 7

```swift
// Rendering modes
Image(systemName: "sparkles")
    .symbolRenderingMode(.hierarchical)          // Depth
    .symbolEffect(.bounce, value: trigger)       // Animate on trigger
    .contentTransition(.symbolEffect(.replace))  // Magic replace

// Baru iOS 26
    .symbolEffect(.draw)                         // Draw animation
    .symbolEffect(.draw.byLayer)                 // Draw per layer
```

## State Management

Project ini menggunakan **ObservableObject + @Published** (bukan @Observable):

```swift
// ViewModel
@MainActor
final class MyViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
}

// View (inject dari factory)
struct MyView: View {
    @ObservedObject private var viewModel: MyViewModel
    
    init(viewModel: MyViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
}
```

## Modifier Order (Penting!)

```swift
Text("Hello")
    .font(.headline)              // 1. Content
    .foregroundStyle(.primary)
    .padding()                    // 2. Layout
    .frame(maxWidth: .infinity)
    .background(...)              // 3. Background
    .shadow(radius: 4)            // 4. Effects
    .onTapGesture { }             // 5. Gestures
    .onAppear { }                 // 6. Lifecycle
    .glassEffect()                // 7. ⚠️ SELALU TERAKHIR (jika dipakai)
```

## Empty States

```swift
ContentUnavailableView(
    "Belum Ada Data",
    systemImage: "tray",
    description: Text("Mulai scan untuk melihat hasil.")
)
```

## Accessibility Minimum

```swift
// Touch target: 44×44pt minimum
// Dynamic Type: gunakan semantic font styles
// VoiceOver: label semua elemen interaktif
Image(systemName: "heart.fill")
    .accessibilityLabel("Favorit")
```

## Performance

```swift
// Lazy loading untuk list panjang
ScrollView {
    LazyVStack { ForEach(items) { ... } }
}

// Cancel tasks saat view hilang
.onDisappear { task?.cancel() }

// Weak self di closures
Task { [weak self] in
    guard let self else { return }
    await self.fetchData()
}
```

## Referensi Apple

| Topik | URL |
|-------|-----|
| HIG Home | https://developer.apple.com/design/human-interface-guidelines/ |
| Color | https://developer.apple.com/design/human-interface-guidelines/color |
| Typography | https://developer.apple.com/design/human-interface-guidelines/typography |
| Materials | https://developer.apple.com/design/human-interface-guidelines/materials |
| Navigation | https://developer.apple.com/design/human-interface-guidelines/navigation |
| Accessibility | https://developer.apple.com/design/human-interface-guidelines/accessibility |
| SwiftUI Docs | https://developer.apple.com/documentation/swiftui |
| SF Symbols | https://developer.apple.com/sf-symbols/ |
| Swift API Guidelines | https://www.swift.org/documentation/api-design-guidelines/ |
