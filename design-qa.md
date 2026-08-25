# Wrap Guide Visual QA — Paper Planning & Guidance

## Comparison setup

- Reference: `/Users/banking/.codex/generated_images/019ff64b-75a7-7da1-bd4c-8fb19f9ae16e/exec-143b7fb1-f53c-47fe-b1a7-0a87a8faef94.png`
- Implementation: `/Users/banking/Desktop/WrapGuide/.build/design-qa/paper-plans-368x800.jpg`
- Guidance state: `/Users/banking/Desktop/WrapGuide/.build/design-qa/guidance-step5-368x800.jpg`
- Combined evidence: `/Users/banking/Desktop/WrapGuide/.build/design-qa/paper-plan-comparison.png`
- Viewport: iPhone Air simulator, portrait, 368 × 800 pt capture
- Pixel normalization: 853 × 1844 reference scaled and padded to 368 × 800; implementation captured at 368 × 800; combined evidence is 736 × 800.
- State: Easy Wrap selected for a 21.4 × 13.8 × 6.2 cm phone box; guidance preview at first-end fold.

## QA passes and fixes

1. **P1 · Layout overflow — fixed.** Initial implementation allowed the cyan allowance guides and amber seam to draw beyond the paper stage. Their paths now derive from local geometry and the scene clips only at its own bounds.
2. **P2 · Visual hierarchy — fixed.** The first pass retained a generic rounded card around the main illustration. The final pass removes that container so the physical paper, roll edges, dimensions, and box form the primary spatial stage, matching the open-canvas reference.
3. **P2 · Measurement clarity — fixed.** The vertical ruler previously rotated a single-line label and could break into individual characters. It now uses a stable two-line measurement label, with blue end caps and a consistent baseline.
4. **P2 · Material fidelity — fixed.** Flat rectangles were replaced by reusable paper material, fiber, rolled edges, contact shadows, folded end creases, and a matte box surface. The same vocabulary is used by paper planning, preparation, home hero, and guidance.
5. **P2 · Motion semantics — fixed.** Guidance no longer relies on a straight arrow over a rectangle. Active paper has a translucent cobalt surface, cyan fold axis and target face, a curved dashed trajectory, a moving position marker, and an amber serrated tape strip.
6. **P2 · Accessibility sizing — fixed.** At extra-extra-extra-large content size, secondary plan copy and compact fact/choice controls were competing for width. The subtitle can now wrap, while diagrammatic compact controls cap at xLarge and retain full accessibility labels.

## Final review

- Typography and hierarchy: passed; plan title, reason, fit state, dimensions, and primary action remain distinct.
- Spacing and layout: passed at 368 pt; the stage remains readable without overlaps and the rest of the flow remains discoverable by scrolling.
- Colors and tokens: passed in light and dark appearance; cyan is reserved for allowance/folds, cobalt for movement/measurement, amber for seams/tape.
- Image/material quality: passed; generated images are visual references only, while runtime visuals stay dimension-aware and programmatic.
- Interaction states: passed for Easy/Just Fit/custom switching and animated guidance/reduce-motion fallback.
- Accessibility: passed for semantic labels, reduced motion behavior, compact Dynamic Type handling, and 44 pt controls.

**Final result: passed**
