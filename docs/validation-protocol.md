# Physical Validation Protocol

## Phase 1 — phone-box measurement loop

Use the paired non-LiDAR iPhone as the authoritative baseline.

1. Measure three phone boxes with calipers or a metal ruler and record ground truth to 1 mm.
2. Test each box on light, dark, and patterned tables at approximately low, normal, and bright indoor light.
3. Complete at least 30 scans. Record raw result, edited result, scan duration, fallback used, tracking interruption, and device temperature.
4. Pass when at least 90% of all three edited dimensions are within the greater of 5 mm or 3% of ground truth, with median scan-to-confirm time no more than 45 seconds.
5. If two tuning rounds fail, keep Vision as a candidate highlighter and make assisted/manual confirmation the default release path.

## Phase 2 — paper and wrapping

- Boxes: phone, shoe, book, chocolate, near-square, and tall rectangular box.
- Paper: 50–90 gsm; matte, glossy, patterned; exact Easy Wrap size, ±10 mm cutting error, oversized, rotated custom, and insufficient.
- Complete at least 30 Easy Wrap sessions. Paper shortage is a release blocker.
- For each AR step, record whether the user understood the movable region, direction, target, and tape point without spoken coaching.
- Relock after moving the box; target recovery time is under 10 seconds.

## Phase 3 — novice usability

- Recruit at least 10 participants who do not regularly wrap gifts.
- Give them the app, a box, paper, scissors, and tape without external instructions.
- Target at least 80% first-attempt completion without intervention and 90% completion with at most one recovery action.
- Record all misunderstandings and paper failures; do not substitute staff demonstrations for participant success.

## Release matrix

- Current non-LiDAR iPhone and iOS release
- At least one older supported iOS 18 device through TestFlight
- LiDAR code remains disabled in the App Store configuration until it passes the same measurement and overlay checks on a Pro iPhone
- Camera allowed, denied, and revoked while the app is installed
- Low light, partial occlusion, non-rectangular box, foreground/background interruption, relocalization failure, and restored session

Store validation measurements only in the developer test report. Do not add user camera captures or AR maps to app telemetry.
