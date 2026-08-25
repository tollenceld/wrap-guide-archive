# Wrap Guide project retrospective

Date: 2026-08-26

## Decision

Development of the combined box scan, real-time AR overlay, and 12-step wrapping guide has stopped. The full source remains recoverable from tag `full-ar-prototype-2026-08-25`; the main branch now contains only a deterministic wrapping-paper planner.

This decision is not a claim that the idea is impossible. It is a recognition that the prototype did not meet the reliability and comprehension bar promised to users, and that continued cosmetic work would not repair its architectural gaps.

## Root causes

### 1. The first release attempted three research problems at once

The product simultaneously tried to estimate a real box, track spatial pose, and teach a novice to manipulate deformable paper. Each part required separate physical validation. They were assembled into a long flow before any single part had crossed its acceptance gate.

### 2. Measurement and guidance were not one spatial system

The scan produced dimensions and an approximate pose, but that pose was not carried into the guidance renderer as a stable, relockable box coordinate system. The RealityKit implementation placed simplified overlay geometry near a center ray. It could look like an AR overlay without being registered to the measured physical box.

### 3. Step identity rebuilt the AR runtime

The guidance view used `.id(step.id)`. Advancing a step therefore recreated the `ARView` and restarted the AR session instead of updating reusable entities. The transition after the body seam was especially likely to stall behind session startup or coaching state. This was an architectural lifecycle bug, not a missing animation.

### 4. A generic scrolling page hid primary actions

The same `ScrollView` page shell was reused throughout the app, so the bottom action could move outside the initial viewport. The UI-test helper repeatedly called `swipeUp()` until a button became hittable. That made tests pass while concealing the product failure.

### 5. Simulator evidence substituted for physical evidence

The simulator displayed bespoke diagrams, while the device used a separate RealityKit path. Tests could advance through all 12 steps by tapping a button but did not prove alignment, comprehension, or successful physical wrapping. Visual QA inspected selected screenshots rather than the complete real task.

### 6. Visual targets outran the implementation model

Generated design images communicated flexible paper, depth, fold sequence, and target state. Runtime primitives were rectangles, lines, and arrows without a physically coherent paper model. Styling those primitives more aggressively increased the contrast between promise and behavior.

## Validation gaps

- No completed 30-scan measurement study with recorded ground truth.
- No 30-session Easy Wrap physical-paper study.
- No 10-person novice completion study.
- No device test proving that a moved box could relock into the same guidance coordinate system.
- No UI gate forbidding scroll-assisted discovery of primary actions.

## What remains useful

- The millimetre-based Easy Wrap and Just Fit formulas.
- Direct/90° custom-sheet fit evaluation that compares actual rectangles, not area alone.
- Unit conversion, bilingual strings, privacy manifest, icon, and deterministic domain tests.
- The lesson that AR must be validated as one end-to-end spatial contract before tutorial breadth is added.

## Conditions for revisiting AR

AR work should restart only as a separate research branch with one physical-box pose, one fold, one device target, recorded ground truth, and a renderer that consumes the exact measured coordinate system without rebuilding the session. It should not be merged into the planner until real users pass that isolated gate.
