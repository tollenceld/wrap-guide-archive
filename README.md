# Wrap Guide

Wrap Guide is a native iPhone app that measures rectangular gift boxes, recommends a practical sheet of wrapping paper, and displays the next fold as a restrained spatial guide.

## Requirements

- Xcode 26 or newer
- iOS 18 or newer
- An ARKit-capable iPhone for live measurement and AR guidance
- XcodeGen (`brew install xcodegen`) when regenerating the project

## Build

```sh
xcodegen generate
xcodebuild -project WrapGuide.xcodeproj -scheme WrapGuide \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

The simulator uses a clearly labeled measurement fixture and diagram guidance. It never presents simulated values as a live camera measurement. Device builds use ARKit, RealityKit, and Vision.

## Architecture

- `AppCoordinator` owns the finite state flow and persists only the active wrapping session.
- `PaperPlanner` is a deterministic, millimeter-based geometry service with no UI dependency.
- `ARScannerView` combines horizontal planes, Vision rectangle candidates, multi-frame stability, and an editable/manual fallback.
- `StandardBoxWrapMethod` defines the 12 steps and local-coordinate overlay primitives.
- `GuidanceCameraView` renders the same primitives as a RealityKit overlay on device and an accessible diagram in the simulator.
- `SwiftDataSessionRepository` stores dimensions, paper choice, mode, and current step. Camera frames and AR maps are never stored.

## Privacy

The app has no networking, accounts, analytics, advertising, tracking, photo-library access, microphone access, or location access. Camera processing stays on device. See [privacy.md](docs/privacy.md).

## Verification

Run all unit and UI tests:

```sh
xcodebuild test -project WrapGuide.xcodeproj -scheme WrapGuide \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Physical measurement and real wrapping must follow [validation-protocol.md](docs/validation-protocol.md). A simulator build cannot validate dimensional accuracy or AR alignment.

## Release blockers

Before App Store submission, the release owner must provide the final bundle ID, legal developer name, public support contact, hosted HTTPS privacy/support URLs, distribution regions, and completed physical validation results. The in-app support copy intentionally marks these fields as pending rather than inventing contact details.

