# Moula iOS — Tech stack, architecture, RevenueCat

## Tech stack

- **Language**: Swift
- **UI framework**: SwiftUI
- **State management**:
  - `ObservableObject` + `@Published` for view models and shared state
  - `@StateObject` / `@EnvironmentObject` for dependency/state injection into views
- **Concurrency**: Swift Concurrency (`async` / `await`) for service calls (example: authentication flow)
- **Persistence (local)**: `UserDefaults` (used for lightweight app state like credits, onboarding flags, dismissed items, etc.)
- **Assets**:
  - Asset catalogs (`.xcassets`) for images/icons
  - Custom fonts bundled in the app and registered at runtime (CoreText font registration in `Moula/OnboardingApp.swift`)
- **Dependencies**: No third‑party dependency manager detected in this repository (no CocoaPods `Podfile`, no SPM `Package.resolved`, no Carthage config)

## Architecture

This codebase follows a **SwiftUI + MVVM** layout with a small **service layer**:

- **App entrypoint / composition root**
  - `MoolaApp` (`Moula/OnboardingApp.swift`) is the `@main` entry.
  - Creates a single global `AppState` (`ObservableObject`) and injects it via `environmentObject`.

- **Routing / screen composition**
  - `ContentView` decides what to show:
    - splash
    - auth flow
    - investor profiling
    - main tab UI
  - High-level navigation is state-driven via `AppState` (`isAuthenticated`, `authFlow`, `currentUser`).

- **Modules (folder structure)**
  - `Moula/Views/`: SwiftUI screens (feature UIs)
  - `Moula/Components/`: reusable SwiftUI components (cards, buttons, UI helpers)
  - `Moula/ViewModels/`: MVVM view models (`ObservableObject`) used by screens
  - `Moula/Services/`: pure Swift “service” objects (auth, local stores, demo data seeding, etc.)
  - `Moula/Models/`: app domain models used by view models and views

- **Data flow (typical)**
  - Views bind to view model `@Published` state.
  - View models call services to read/write local state (currently `UserDefaults`) and to perform async work.
  - Services are simple, mostly synchronous/pure where possible, with `async` APIs used for flows like authentication.

## RevenueCat implementation

**RevenueCat is not currently integrated in this repository.** The app includes paywall UI components and “hook points” for a future purchase/subscription flow (for example, paywall sheets that currently dismiss but do not start a purchase).

If/when RevenueCat is added, the intended integration points are:

- **SDK installation**: add the RevenueCat Purchases SDK (recommended via Swift Package Manager in Xcode).
- **Configure at app launch**: in `MoolaApp` initialization:
  - call `Purchases.configure(...)`
- **Offerings / packages**:
  - fetch offerings (e.g. “trial”, “monthly”, “yearly”) and bind results to paywall screens
- **Purchase**:
  - trigger purchase on the paywall CTA
  - update app state based on entitlements (e.g. unlock “Insights” / “Infinite”)
- **Restore purchases**:
  - provide a restore button and handle `restorePurchases()` result

