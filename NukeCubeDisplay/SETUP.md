# NukeCube — Setup & What Was Built

## Project setup

Same situation as the Month Dodecahedron project: this sandbox has no
Xcode/visionOS toolchain, so these are plain Swift source files, not a
buildable `.xcodeproj`.

1. Xcode → **File → New → Project → visionOS → App**.
2. Delete the template's default `ContentView.swift` / app file.
3. Drag in `App/`, `Data/`, `Geometry/`, and `Rendering/` as groups.
4. Add `Resources/cube_data.json` to the target — make sure it's checked
   under **Target → Build Phases → Copy Bundle Resources** (Xcode usually
   does this automatically when you drag a loose file into a target with
   "Copy items if needed" checked, but it's worth confirming, since a
   missing bundle resource is the most common cause of `CubeDataLoader`'s
   `fatalError` on launch).
5. Build & run on a Vision Pro simulator or device (visionOS 2.0+ — this
   uses the two-parameter `RealityView { content, attachments in ... }
   attachments: { ... }` initializer, which requires it).

## How each requested section was implemented

**Section 2 (data corrections):** `Resources/cube_data.json` already
reflects all three corrections from the brief — 21 participants, Face 2's
actual top statement (s32, the natural-gas bridge), and all seven consensus
statements (flagged via `isConsensus`) — since it was generated directly
from the report's full score table rather than transcribed from the spec.
No app code needed to change for this; it was a data-generation concern,
already resolved before this build started.

**Section 5 (four-panel carousel):** `CubeTwistController` implements the
cheaper alternative recommended in the brief instead of true per-layer
cubie decomposition. The four face panels sit at fixed 90-degree positions
around a vertical axis and the whole assembly rotates as one rigid object
when twisted — no sub-cube re-partitioning, no per-sticker reassignment.
`CubeGeometry.carouselRadius` controls how far apart the faces sit; increase
it if a future pass makes the grids larger and panels start clipping into
each other at the corners.

**Section 7 (billboard panels):** `ImmersiveView` places two SwiftUI
`RealityView` attachments — `InstructionsPanelView` to the left of the cube
and `StatementPanelView` to the right — each carrying a `BillboardComponent`
so they stay facing the user from any angle. Tapping a cubie updates
`selectedCubie`, which `StatementPanelView` renders reactively; the
instructions panel is static content plus a small "currently viewing"
readout that updates on every twist via `CubeTwistController.onFrontFaceChanged`.

**Section 9 (strictly four perspectives):** nothing in the report's
unassigned/cross-loading participants made it into the data model or the
UI — `cube_data.json`'s `faces` array has exactly four entries, one per
shared perspective, and that's the only unit the app knows how to render.

## Known gaps / next steps

- The two twist buttons are simple flat squares with a glyph texture, not a
  polished 3D control — fine for validating the interaction, worth a design
  pass before this goes in front of stakeholders.
- No idle/attract-mode motion yet. The Month Dodecahedron brief noted that
  hidden content needs a discoverability nudge; the same is arguably true
  here for the *back* two panels of the carousel (the two perspectives not
  currently front or adjacent) — worth considering once the four-panel
  layout is validated.
- Billboard panel placement (`cubeRootPosition.x ± 1.0`) is a fixed offset
  tuned by eye, not measured against the actual rendered carousel width —
  revisit once this is running on-device and the panels can be checked for
  overlap with the twist buttons at the extremes.
