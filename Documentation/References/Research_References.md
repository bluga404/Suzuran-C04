# Research References

This project baseline is aligned with the references below.

## Apple and Swift Official References

1. SwiftUI App lifecycle (`App` protocol):
   https://developer.apple.com/documentation/swiftui/app

2. SwiftUI NavigationStack and path-driven navigation:
   https://developer.apple.com/documentation/swiftui/navigationstack

3. Human Interface Guidelines, Launching:
   https://developer.apple.com/design/human-interface-guidelines/launching

4. Xcode launch screen implementation guide:
   https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen

5. Swift API Design Guidelines (naming and documentation):
   https://www.swift.org/documentation/api-design-guidelines/

6. Xcode markup formatting reference for code comments and Quick Help:
   https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/

## Practical Architecture References

1. Clean Architecture for SwiftUI (layer separation concepts and dependency direction):
   https://nalexn.github.io/clean-architecture-swiftui/

2. Dependency Injection in Swift with protocols (protocol composition and factory ideas):
   https://swiftwithmajid.com/2019/03/06/dependency-injection-in-swift-with-protocols/

## Key Takeaways Applied in This Base Project

- Use a single composition root to build dependencies.
- Keep domain contracts free from framework details.
- Map DTOs to domain entities before reaching presentation.
- Keep startup launch experience system-managed and instant.
- Use strict naming and documentation discipline to sustain team scale.
