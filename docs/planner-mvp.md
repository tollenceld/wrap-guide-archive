# Planner MVP boundary

## Product promise

Given a rectangular box's length, width, and height, Wrap Guide calculates a practical rectangular sheet size and evaluates an existing sheet without requesting any permission.

## Flow

1. **Input** — enter three box dimensions and choose automatic, metric, or imperial display units.
2. **Results** — compare Easy Wrap and Just Fit while viewing a proportional top-down layout.
3. **Check existing paper** — enter sheet width and height; receive roomy, comfortable, precise, or insufficient status, a 0°/90° placement result, minimum cut size, and a cutting recommendation.

Every primary action is attached with `safeAreaInset(edge: .bottom)` and remains reachable without scrolling. Content may scroll at large Dynamic Type sizes, but the action does not.

## Formulas

For box axis `X`, perpendicular horizontal axis `Y`, and height `H`:

- wrap-around size: `2 × (Y + H) + seam overlap`
- end-to-end size: `X + 2 × H + 2 × end allowance`

Easy Wrap uses 30 mm seam overlap and 15 mm allowance at each end. Just Fit uses 15 mm seam overlap and 5 mm allowance at each end. Both axes are evaluated, the smaller required area is selected, and dimensions round upward to 5 mm.

## Existing-sheet evaluation

The planner checks the required cut rectangle against the available sheet at 0° and 90° for both box orientations. It does not claim feasibility from area alone. It also does not offer an arbitrary diagonal result: without a validated cutting/placement model, that would overstate what this MVP can guarantee.

## Explicitly out of scope

- camera measurement, ARKit, RealityKit, Vision, depth, or pose tracking;
- three-dimensional folding visuals or step-by-step wrapping instruction;
- non-rectangular gifts or paper;
- accounts, history, cloud sync, analytics, advertising, or networking;
- persistence beyond the local unit preference.

## Status

Version 0.1 is an internal minimum usable version. It is intentionally not described as an App Store release candidate.
