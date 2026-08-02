# Launch Screen and App Flow

## Objective

Use a proper iOS launch screen (system-managed), not a delayed custom splash implementation.

## Current Implementation

- `LaunchScreen.storyboard` exists and is configured in target settings.
- `INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen`.
- App opens directly to Home (`Welcome to Suzuran`).
- No artificial timer-based splash in SwiftUI.

## Why This Is Correct

Apple HIG and Xcode guidance require launch screens to:

- appear instantly,
- be quickly replaced by first app content,
- avoid being used as an advertising/splash canvas,
- closely resemble initial UI visual foundation.

This project follows that by using a plain visual launch screen and entering the first screen immediately.

## Do and Do Not

Do:

- keep launch screen static,
- keep layout simple and adaptive,
- match first-screen visual tone.

Do not:

- run async logic inside launch screen,
- add animation to launch screen,
- delay routing only for branding.

## Startup Error Handling

The app still performs bootstrap work in `RootViewModel.start()`.
If bootstrap fails, it transitions to a reusable error state and offers retry.
This preserves reliability while keeping launch UX compliant.
