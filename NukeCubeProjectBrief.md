# Project Brief: NukeCube
### A visionOS spatial visualization of the Delaware SMR stakeholder perspectives
Prepared from `NukeCubeSpec.txt` and `Systems_Thinking_Project_Final_Report.pdf`

---

## 1. What this app is

A dark, immersive visionOS space with one large Rubik's-cube-like object floating
at its center. Each of its four vertical faces represents one of the four
stakeholder perspectives identified by SERI's Q-methodology study of the
Delaware Nuclear Energy Feasibility Task Force. Each face is a 3×3 grid: an
oversized, glowing center square holds that perspective's single most
defining conviction, and eight surrounding squares ("cubies") hold its
secondary positions — including, notably, the arguments it actively rejects.
Rotating a row/layer of the cube brings a slice of one face into view
alongside another, so a user can visually discover where two perspectives
that seem opposed actually share ground.

This is the same core interaction problem as the Month Dodecahedron project —
readable text glowing on the face of a 3D solid the user can look at from
different angles — so most of this brief reuses that project's solved
problems (text-as-texture, per-face tap targets) and spends its effort on
what's genuinely new: **a cube whose faces can actually be twisted**, and
**real stakeholder data** rather than a calendar.

## 2. Reconciling the two source documents

`NukeCubeSpec.txt` is a podcast-style narrative that describes the vision for
this app vividly, but it's a paraphrase — and it doesn't always match the
underlying report. Three discrepancies worth resolving before anyone starts
building content into the app:

| Spec says | Report actually says | Recommendation |
|---|---|---|
| Task force of 20 people | **21** participants completed the Q sort | Use 21 |
| Face 2 ("Delaware Must Act")'s core conviction is generation urgency / jobs | Its single most characteristic statement is actually about building **natural gas as a bridge to SMRs** (s32, +3.31) — the report states this explicitly | Use the report's number |
| Three universal consensus statements | The report identifies **seven** consensus statements (all four perspectives agreeing, same direction, low spread) | Use all seven |
| Bell-curve grid described loosely | Report specifies real forced-sort scores from -5 to +5, threshold-tested for statistical significance (p<.05, n=21) | Use raw scores, not a stylized bell curve, for face content |

The other three faces' core convictions in the spec check out exactly against
the report (Face 1 → s37 financial accountability; Face 3 → s5 "not yet"
commercial proof; Face 4 → s18 social license) — so the spec is a reasonable
guide to the *interaction design*, just not the source of truth for *content*.
**The report is the source of truth for every statement, score, and
perspective name that ends up in the app.**

## 3. Data model (already built)

Rather than leave this as a to-do, the four faces' content has been computed
directly from the report's full 38-statement × 4-perspective score table —
the same table underlying its "distinguishing statements" sections — and
saved as `cube_data.json` alongside this brief. For each perspective, the
script:

1. Picks the single **highest-scoring statement** as the center cubie (this
   matches the report's own narrative language — e.g. "the most
   characteristic statement is s37" — in all four cases, which is a good
   sanity check on the approach).
2. Picks the **eight statements with the largest score magnitude** (positive
   or negative) as the surrounding cubies, tagging each `affirm` or `reject`
   depending on sign.
3. Flags any cubie whose statement is one of the report's seven **consensus
   statements**, so the app can render those distinctively (e.g., a shared
   glow color) regardless of which face they appear on — this is the data
   hook for the spec's "twist and see the alignment" moment.

This is a deliberate, reviewable rule, not a black box — but it's a rule, and
someone with domain knowledge of the report should sanity-check the resulting
36 cubies (4 centers + 32 secondary) before they're locked into launch
content, the same way you'd proofread generated copy.

## 4. What carries over from the Month Dodecahedron project

| Solved problem | Reused as-is |
|---|---|
| Rasterizing text to a texture and mapping it onto a mesh face (`TextTexture.swift` pattern) | Directly reusable — cube faces are simpler than pentagons (flat squares), so the UV math is trivial by comparison |
| The V-coordinate flip we debugged | Apply that lesson from day one instead of rediscovering it |
| `InputTargetComponent` + `CollisionComponent` + `HoverEffectComponent` + a custom `Component` carrying semantic data, for tap-to-inspect | Reused per-cubie, not just per-face — every one of the 36 cubies becomes its own tappable entity |
| Tap → console log → scale "pulse" as an interaction stub | Reused as the baseline; see §7 for what should replace it |

What's **not** reusable: the dodecahedron's geometry code, since a Rubik's
cube's mesh and (especially) its interaction model are a different problem
entirely — see §5.

## 5. What's actually new and hard: a cube that twists

This is the part of the spec that carries real engineering risk, and it
deserves to be scoped honestly rather than glossed over:

- **A visual Rubik's cube face is easy.** Nine flat squares per face, laid
  out in a grid, is a straightforward `RealityKit` scene — comparable
  difficulty to the dodecahedron.
- **A cube whose layers can be grabbed and rotated is a different problem.**
  A mechanically real Rubik's cube requires decomposing the object into up to
  27 sub-cubes ("cubies," in the puzzle-solving sense — note this
  overloads the report's use of "cubie" for a face square, so the brief and
  code should pick one term per concept to avoid confusion), each carrying
  the correct sticker(s) on its exposed faces, plus logic to:
  - Detect which layer (row or column, on which axis) a drag gesture intends
    to rotate.
  - Animate that layer's 90° rotation while the rest of the cube stays still.
  - Re-partition which physical sub-cubes belong to which layer afterward,
    since a twist changes that assignment.
  - Keep every sticker's semantic identity (which statement it represents)
    attached correctly through all of this, so a tap always reports the
    right statement.

- **A cheaper alternative that may serve the actual goal better:** the spec's
  real payoff is the *reveal* — seeing an adjacent face's cubies rotate into
  view next to your own. That doesn't strictly require a physically accurate
  twisting mechanism. A four-panel "carousel" that animates a slice of the
  neighboring face swinging into view when the user performs a twist
  gesture, without a true cubie-decomposition model underneath, would look
  and feel very similar to the user, at a fraction of the engineering cost
  and risk. **This is a scope decision worth raising with stakeholders
  before committing engineering time**, not something to silently decide in
  code.

## 6. Proposed architecture (visionOS / RealityKit)

```
NukeCube/
  App/
    NukeCubeApp.swift          — WindowGroup + ImmersiveSpace, same shape as before
    ContentView.swift          — launcher window
    ImmersiveView.swift        — builds the cube, owns twist-gesture state
  Geometry/
    CubeGeometry.swift         — face/cubie layout, plane meshes (simpler than the dodecahedron's custom MeshDescriptor math)
    CubeTwistController.swift  — NEW: owns which layer is "live," current rotation angle, and re-partitioning after a completed twist (see §5 for scope decision this depends on)
  Data/
    CubeData.swift             — Codable models mirroring cube_data.json; loads it as a bundled resource
  Rendering/
    TextTexture.swift          — carried over from Month Dodecahedron with the V-flip fix already applied
    CubieMaterial.swift        — NEW: adds the affirm/reject/consensus color treatment on top of TextTexture
  cube_data.json               — bundled data asset (already generated, see §3)
```

## 7. Interaction and future-version discussion (parallel to the month app)

Per the same "discuss the future interaction" ask from the calendar project,
here's how tapping a cubie should evolve:

- **Immediate (in scope for v1):** tapping any cubie shows its full statement
  text and score in a nearby `RealityView` attachment (a real SwiftUI view,
  not another texture — this is the same recommendation made for the
  calendar app, and it matters more here since statement text is much longer
  than a month name and needs real text wrapping and accessibility support).
- **Near-term:** tapping a *center* cubie could highlight, across all four
  faces simultaneously, any other face where that same statement scores in
  the same direction — a data-driven version of the spec's "twist to
  discover alignment" moment that doesn't require the user to physically
  find the right twist.
- **Matches the spec's own stretch goal:** the spec's closing thought — an AI
  that listens to a live town hall and projects the aligned cube in real
  time — is explicitly speculative future work in the source material
  itself, not a v1 requirement. It implies a live NLP pipeline mapping
  freeform speech onto the 38-statement space, which is a separate research
  effort from this visualization app and shouldn't be scoped into this
  brief's timeline.

## 8. Suggested milestones

1. **Static cube, real data** — four faces, 3×3 grids, correct text per §3,
   no interaction beyond looking at it. Validates the text-rendering
   pipeline reused from the calendar project.
2. **Tap-to-inspect** — per-cubie components, attachment-based detail view.
3. **Twist decision point (§5)** — stakeholder go/no-go on true cubie
   decomposition vs. carousel-style reveal, before further interaction work.
4. **Twist mechanics** — implement whichever approach was chosen in
   Milestone 3.
5. **Consensus highlighting** — cross-face alignment cues, tying back to the
   seven consensus statements.
6. **Polish** — lighting, idle motion/discoverability (the calendar brief's
   note about the dodecahedron's hidden back faces applies here too: the
   value of this app is in what's *not* immediately visible, so making that
   discoverable matters).

## 9. Open questions for stakeholders

- Confirm the correction of the three discrepancies in §2 before any content
  is locked.
- Decide the twist-mechanism scope question in §5 — this is the single
  biggest driver of project timeline.
- Should the six unassigned/cross-loading task force participants (mentioned
  in the report but not defining any single perspective) appear anywhere in
  the experience, or is this strictly a four-perspective visualization?
