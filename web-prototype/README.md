# Clear30 · Cravings Navigation Prototype

A throwaway React prototype for iterating on the **cravings flow navigation** before
touching the SwiftUI app. It clones the Clear30 design language (Lexend, the gradient
card tokens, soft rounded cards) so the focus stays on layout/navigation, not visuals.
Games are stand-ins — the point is the wayfinding, not the gameplay.

## Run

```bash
cd web-prototype
npm install
npm run dev
```

Opens at http://localhost:5180.

## What's here

A phone frame showing the Support tab. Tap **Cravings** to open the flow. The toggle above
the phone switches between two navigation models:

- **Current** — faithful clone of today's `CravingInterventionFlow`: intensity question →
  one game per level → a heavy post-game screen (best score, rating monster, "still
  craving?", 12-level grid, four actions). Meditations are not reachable.
- **Redesign** — a **category hub** surfacing Meditations / Breathwork / Games up front.
  Each category uses a *distinct* visual language so nothing looks like the red Cravings
  button:
  - Meditations → horizontal **audio rail** + full library list + mock player
  - Breathwork → a soft **feature panel**, cadence chosen via **chips** (not gradient cards)
  - Games → a playful **2-up tile grid**, with a trimmed-down post-game (one question,
    levels tucked behind a disclosure)

## Map to the SwiftUI source

| Prototype file        | SwiftUI origin                                   |
| --------------------- | ------------------------------------------------ |
| `tokens.js`/`styles`  | `Colors.swift`, `GlobalData.swift`               |
| `SupportTab.jsx`      | `MockSupportView.swift` / `Support2.swift`       |
| `CurrentFlow.jsx`     | `CravingInterventionFlow`, `IntensitySelectView`, `PostGameView` |
| `Breathing.jsx`       | `BreathingStyles.swift` (`BreathingView`, cadence picker) |
| `GamePlaceholder.jsx` | stand-in for PushPull/PatternRepeat/Slice games  |
