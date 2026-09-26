# Current State

## Phase 0 status

The repository contains a minimal native SwiftUI macOS application named Materials Intelligence. Xcode 27.0 (build 27A266a) and Swift 6.4 are installed. The deployment target is macOS 15.0. The project uses no third-party libraries, web runtime, database, search, AI, cloud, mobile target, or engineering functionality.

## Files and structure

- `MaterialsIntelligence.xcodeproj/`
- `MaterialsIntelligence/App/MaterialsIntelligenceApp.swift`
- `MaterialsIntelligence/UI/RootView.swift`
- the six permanent project documents
- `UI-UX Sketches/` reference images

## Verification

The Release target builds successfully with `xcodebuild` using the installed Xcode toolchain. The app is configured with an unsigned local build for development verification. The built app was launched successfully during Phase 0 verification.

## Next action

When explicitly authorized, begin Phase 1 by adding the professional native macOS application shell and navigation structure. Do not add knowledge models, search, AI, or research ingestion during that work.
