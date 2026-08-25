# Wrap Guide

Wrap Guide is an internal iPhone minimum viable product for planning rectangular wrapping paper. It intentionally does three things only:

1. accepts a box's length, width, and height;
2. recommends Easy Wrap and Just Fit paper sizes;
3. checks whether an existing rectangular sheet fits directly or after a 90° rotation, and shows an exact cut target.

The previous camera-measurement and AR-guidance prototype is preserved in Git tag `full-ar-prototype-2026-08-25`. It is not part of the current app and is not considered release-ready.

## Requirements

- Xcode 26 or newer
- iOS 18 or newer
- XcodeGen when regenerating the project

No camera, AR-capable device, account, network connection, or system permission is required.

## Build and test

```sh
xcodegen generate
xcodebuild -project WrapGuide.xcodeproj -scheme WrapGuide \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild test -project WrapGuide.xcodeproj -scheme WrapGuide \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Structure

- `PlannerCoordinator` owns the two-route input/results flow.
- `PaperPlanner` contains deterministic millimetre-based formulas and custom-sheet evaluation.
- `PaperLayoutDiagram` renders only dimensionally truthful 2D paper, box, allowance, seam, and cut geometry.
- `docs/planner-mvp.md` defines the supported product boundary.
- `docs/project-retrospective.md` records why the original AR direction was stopped.

## Status

This is an internal minimum usable version, not the current App Store candidate. It has no accounts, networking, analytics, tracking, or requested permissions. See [Privacy](docs/privacy.md).
