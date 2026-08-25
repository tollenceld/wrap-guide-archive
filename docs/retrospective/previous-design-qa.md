# Historical visual QA attempt

This document archives a review that was previously marked **passed**. That conclusion is withdrawn.

The review compared selected simulator screenshots at one viewport and verified surface-level layout details. It did **not** establish that the physical-device scan was reliable, that the AR geometry was aligned with the measured box, that the guidance transition after the body seam remained live, or that primary actions were reachable without scrolling. The former UI test even scrolled automatically before tapping, masking the exact interaction failure reported by the user.

## What the historical review covered

- A generated paper-plan target versus `assets/implemented-paper-plan.jpg`.
- A simulator guidance state in `assets/implemented-ar-guidance.jpg`.
- 368 × 800 pt presentation, color roles, typography, and a reduced-motion fallback.

## Why its result was invalid

- Generated references were more expressive than the runtime geometry and could not prove usability.
- Simulator diagrams were not equivalent to RealityKit behavior on a device.
- No novice completed a real wrap as part of this review.
- The review treated discoverability by scrolling as acceptable even though the task required fixed, immediately tappable actions.
- It did not exercise the AR-session rebuild at every step.

The assets remain only as evidence of the explored design direction. They are not linked into the application bundle.
