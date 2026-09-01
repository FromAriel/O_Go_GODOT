# O Go GODOT — Execution Checklist

This file is the terse implementation ledger for `docs/PHASED_BUILD_PLAN.md`.

It is intentionally narrower than Git history and intentionally shorter than the planning documents.

For each implementation turn, record:

```text
phase/task IDs touched
files/systems changed
validation actually run
result
new TODOs discovered
next logical task
```

Do not claim validation that was not actually run.

---

# Current Status

**Current phase:** P3 — Constants and tuning infrastructure

**Current next action:** Begin P3.1–P3.4 by formalizing configuration-vs-constant conventions and lightweight review guidance before the project model starts consuming tunable settings.

---

# Phase Ledger

## P0 — Governance and execution contract

- [x] P0.1 Maintain existing vision document as product-direction authority.
- [x] P0.2 Maintain `docs/MVP_BUILD_PLAN.md` as MVP feature/architecture authority.
- [x] P0.3 Add `docs/PHASED_BUILD_PLAN.md` as dependency-aware implementation order.
- [x] P0.4 Add `CHECKLIST.md` as terse execution ledger.
- [x] P0.5 Record separation-of-concerns and no-monolith rules.
- [x] P0.6 Record data-driven/editor-code-parity rules.
- [x] P0.7 Record TODO/placeholder philosophy.
- [x] P0.8 Record magic-number/constants documentation policy.
- [x] P0.9 Record universal numeric bounds/slider contract.
- [x] P0.10 Review repository conventions during first implementation turn and adjust only where real code exposes a need.

## P1 — Shared primitives and diagnostics

- [x] P1.1 Define stable ID representation/convention.
- [x] P1.2 Define bounds/range metadata primitives.
- [x] P1.3 Define world/grid position conventions.
- [x] P1.4 Define direction representation.
- [x] P1.5 Define asset/content reference primitive.
- [x] P1.6 Define validation result and diagnostic structures.
- [x] P1.7 Add focused tests/validation.
- [x] P1.8 Review module boundaries before phase close.

## P2 — Universal property metadata and bounded controls

- [x] P2.1 Define authoritative tunable-property metadata.
- [x] P2.2 Support recommended vs. hard bounds.
- [x] P2.3 Support defaults, units, steps, rationale, consequences.
- [x] P2.4 Implement property validation.
- [x] P2.5 Build reusable numeric inspector control.
- [x] P2.6 Implement legal-outside-recommended warnings.
- [x] P2.7 Test bound/extreme cases.
- [x] P2.8 Review editor/runtime metadata parity.

## P3 — Constants and tuning infrastructure

- [ ] P3.1 Establish project configuration vs. runtime constant conventions.
- [ ] P3.2 Establish centralized tuning locations where appropriate.
- [ ] P3.3 Apply documentation rule to non-obvious constants.
- [ ] P3.4 Add review guidance for unexplained critical literals.

## P4 — Project model

- [ ] P4.1 Define project manifest schema.
- [ ] P4.2 Implement project loader.
- [ ] P4.3 Support 16/32/64 base tile sizes.
- [ ] P4.4 Define starting map/spawn configuration.
- [ ] P4.5 Add project validation diagnostics.
- [ ] P4.6 Ensure downstream code does not hardcode 32px tiles.
- [ ] P4.7 Load a minimal game project through project data.

## P5 — Content registry and reference resolution

- [ ] P5.1 Register stable content definitions.
- [ ] P5.2 Resolve stable IDs.
- [ ] P5.3 Detect duplicate IDs.
- [ ] P5.4 Diagnose missing references.
- [ ] P5.5 Keep content lookup separate from object instantiation.

## P6 — Map data model

- [ ] P6.1 Define map identity/dimensions/environment.
- [ ] P6.2 Define semantic layer data.
- [ ] P6.3 Define placed objects/actors/triggers/spawns.
- [ ] P6.4 Add map extension/custom metadata path.
- [ ] P6.5 Implement serialization/deserialization.
- [ ] P6.6 Add round-trip tests.

## P7 — Tile terrain rendering

- [ ] P7.1 Render terrain from map data.
- [ ] P7.2 Render ground decoration.
- [ ] P7.3 Render liquid/water layer.
- [ ] P7.4 Support basic animated tiles.
- [ ] P7.5 Add tiny developer tileset.
- [ ] P7.6 Verify rendering derives from project tile size.

## P8 — Collision infrastructure

- [ ] P8.1 Implement no/full/rectangle/polygon tile collision.
- [ ] P8.2 Implement prop collision independent of sprite size.
- [ ] P8.3 Add spatial debug-drawing foundation.
- [ ] P8.4 Verify collision behavior at project tile scales.

## P9 — Actor foundation

- [ ] P9.1 Define focused Actor base concerns.
- [ ] P9.2 Implement Player actor specialization.
- [ ] P9.3 Implement simple NPC specialization.
- [ ] P9.4 Keep inventory/quests/combat/dialogue implementation out of Actor base.
- [ ] P9.5 Review for God-object creep.

## P10 — Movement system

- [ ] P10.1 Define movement intent abstraction.
- [ ] P10.2 Implement actor motor.
- [ ] P10.3 Implement continuous eight-direction movement.
- [ ] P10.4 Normalize diagonal movement.
- [ ] P10.5 Separate player input from motor/physics.
- [ ] P10.6 Expose movement tuning through universal property metadata.
- [ ] P10.7 Test extreme legal movement values.

## P11 — Camera system

- [ ] P11.1 Implement target following.
- [ ] P11.2 Implement offset.
- [ ] P11.3 Implement smoothing.
- [ ] P11.4 Implement bounds.
- [ ] P11.5 Verify camera ownership remains outside Player.

## P12 — Props and placed world objects

- [ ] P12.1 Define reusable prop data.
- [ ] P12.2 Support visual/transform/anchor/collision/sorting metadata.
- [ ] P12.3 Leave animation/interaction/component extension points.
- [ ] P12.4 Implement tile/half/quarter/eighth/free editor placement model.
- [ ] P12.5 Add tree/barrel/sign/flower/archway development examples.

## P13 — Spatial sorting and overhangs

- [ ] P13.1 Implement ground-anchor Y sorting.
- [ ] P13.2 Implement optional base/overhang visual split.
- [ ] P13.3 Verify walk-behind tree behavior.
- [ ] P13.4 Verify walk-in-front behavior.
- [ ] P13.5 Verify pass-under arch behavior.
- [ ] P13.6 Confirm no prop-specific sorting hacks are required.

## P14 — Animation subsystem

- [ ] P14.1 Define reusable animation data.
- [ ] P14.2 Support frames/FPS/loop/phase/random start/playback mode.
- [ ] P14.3 Animate water.
- [ ] P14.4 Animate flower.
- [ ] P14.5 Animate representative prop.
- [ ] P14.6 Verify multiple placed instances can desynchronize.

## P15 — Interaction framework

- [ ] P15.1 Define Interactor/InteractionQuery/Interactable/InteractionAction boundaries.
- [ ] P15.2 Implement show-text action.
- [ ] P15.3 Implement talk action hook.
- [ ] P15.4 Implement transition action hook.
- [ ] P15.5 Confirm no central type-switch interaction monolith.

## P16 — Dialogue MVP

- [ ] P16.1 Define structured dialogue data.
- [ ] P16.2 Implement speaker/text/pages.
- [ ] P16.3 Implement advance/close presentation.
- [ ] P16.4 Connect NPC/sign interactions to dialogue data.
- [ ] P16.5 Preserve future schema extension points without implementing them.

## P17 — Map transitions and world routing

- [ ] P17.1 Define SpawnPoint.
- [ ] P17.2 Define Transition.
- [ ] P17.3 Implement MapRouter.
- [ ] P17.4 Support destination map + named spawn references.
- [ ] P17.5 Prove Meadow → House → Meadow flow.

## P18 — State model and save/load

- [ ] P18.1 Define versioned SaveState schema.
- [ ] P18.2 Save intentional player/world/map/actor/flag state.
- [ ] P18.3 Add future inventory/quest/custom namespaces.
- [ ] P18.4 Add initial migration/version hook.
- [ ] P18.5 Save → quit → load → restore acceptance test.

## P19 — Inspector/editor foundation

- [ ] P19.1 Stable-ID selector.
- [ ] P19.2 Asset picker.
- [ ] P19.3 Universal numeric bounded control.
- [ ] P19.4 Vector/position control.
- [ ] P19.5 Collision editor/viewer.
- [ ] P19.6 Tag editor.
- [ ] P19.7 Reference picker.
- [ ] P19.8 Diagnostic display.
- [ ] P19.9 Verify editor uses authoritative project/property data.

## P20 — Map authoring tools

- [ ] P20.1 Select/open map.
- [ ] P20.2 Select semantic layer.
- [ ] P20.3 Paint/erase tiles.
- [ ] P20.4 Place/move/delete props.
- [ ] P20.5 Place actors.
- [ ] P20.6 Place spawn points/transitions.
- [ ] P20.7 Toggle collision/anchor debug overlays.
- [ ] P20.8 Save map.
- [ ] P20.9 Play-test map.
- [ ] P20.10 Confirm no shadow editor database exists.

## P21 — Project creation UI

- [ ] P21.1 New-project name/ID fields.
- [ ] P21.2 Tile-size selector.
- [ ] P21.3 Movement presentation selector.
- [ ] P21.4 Starting-map selector.
- [ ] P21.5 Open/select existing project.
- [ ] P21.6 Ensure UI calls same underlying services available to code/scripts.

## P22 — Demo project assembly

- [ ] P22.1 Build Meadow.
- [ ] P22.2 Build House interior.
- [ ] P22.3 Add water/flowers/trees/sign/NPC/house.
- [ ] P22.4 Complete full MVP acceptance chain.

## P23 — Hardening and MVP certification

- [ ] P23.1 Broken-reference tests.
- [ ] P23.2 Missing/bad asset tests.
- [ ] P23.3 Malformed data tests.
- [ ] P23.4 Duplicate-ID tests.
- [ ] P23.5 Save corruption/version tests.
- [ ] P23.6 Tile size 16 test.
- [ ] P23.7 Tile size 32 test.
- [ ] P23.8 Tile size 64 test.
- [ ] P23.9 Extreme legal configuration tests.
- [ ] P23.10 Collision edge-case tests.
- [ ] P23.11 Map-transition failure tests.
- [ ] P23.12 Record MVP certification evidence.

## P24 — Architecture review before feature expansion

- [ ] P24.1 Audit oversized modules.
- [ ] P24.2 Audit circular dependencies.
- [ ] P24.3 Audit God objects.
- [ ] P24.4 Audit duplicate schemas.
- [ ] P24.5 Audit editor/runtime coupling.
- [ ] P24.6 Audit hardcoded tile/map assumptions.
- [ ] P24.7 Audit prop/NPC special cases.
- [ ] P24.8 Audit unexplained constants.
- [ ] P24.9 Audit diagnostics.
- [ ] P24.10 Audit serialization/migration risks.
- [ ] P24.11 Resolve structural blockers before post-MVP expansion.

---

# Turn Log

## 2026-09-01 — Planning baseline

**Phase/task IDs:** P0.1–P0.9

**Changed:**
- Added dependency-aware phased implementation plan.
- Added this execution ledger.
- Formalized module-size, separation-of-concerns, data-driven, TODO, constants, and universal tunable-value rules.

**Validation actually run:**
- Documentation-only change; no runtime validation required.

**Result:**
- Planning/governance baseline established.

**New TODOs:**
- P0.10: reconcile conventions against real implementation only when Phase 1 exposes a concrete need.

**Next logical task:**
- Review/approve phased order, then begin P1 shared primitives and diagnostics.

## 2026-09-01 — P1 shared primitives and diagnostics

**Phase/task IDs:** P0.10, P1.1–P1.8

**Changed:**
- Added stable ID convention and validator.
- Added reusable hard/recommended range primitive.
- Established Vector2 world-pixel and Vector2i grid-cell conventions with data-supplied cell size.
- Added eight-direction representation with normalized diagonal vectors.
- Added stable content/asset reference primitive.
- Added structured Diagnostic and ValidationResult primitives.
- Added focused headless P1 tests and a reusable Godot core-validation workflow.

**Validation actually run:**
- GitHub Actions / Godot 4.7.2 official standard Linux x86_64.
- `godot --headless --editor --import --quit --path .` — PASS.
- `godot --headless --check-only --quit --path .` — PASS.
- `tests/core/test_shared_primitives.gd` — initial run found one StableId empty-segment bug; fixed.
- Focused rerun after fix — PASS.

**Result:**
- P1 complete. Shared primitives remain small and dependency-light; native Godot spatial types are retained rather than wrapped unnecessarily.

**New TODOs:**
- None required for P1. P2 will extend RangeSpec into authoritative tunable-property metadata and UI-facing validation.

**Next logical task:**
- Begin P2.1–P2.4 property metadata and validation before building the bounded numeric inspector control.

## 2026-09-01 — P2 tunable-property metadata foundation

**Phase/task IDs:** P2.1–P2.4, P2.7 (test authored; run pending)

**Changed:**
- Added `TunablePropertySpec` as the single authoritative numeric-property metadata resource.
- Added stable property IDs, display names, descriptions, defaults, units, editor step, rationale, consequences, and `RangeSpec` integration.
- Added definition validation for malformed IDs, missing display names/ranges, invalid bound ordering, out-of-range defaults, and negative editor steps.
- Added runtime value validation that warns outside recommended bounds but errors only outside legal hard bounds.
- Kept editor step as UI increment metadata rather than a restriction on manually entered legal values.
- Added focused metadata/extreme-value tests and extended Core Validation to run them after P1 tests.

**Validation actually run:**
- On the commit containing the metadata/test files, the existing Godot 4.7.2 workflow completed project import, project parse, and P1 regression tests successfully.
- The updated workflow that actually executes `tests/core/test_tunable_property_spec.gd` was queued at the end of that turn.

**Result:**
- P2.1–P2.4 implementation complete.
- P2.7 remained open at the end of that turn pending focused behavioral execution.
- P2.5–P2.6 inspector UI work intentionally had not started yet.

**New TODOs:**
- Complete P2.7 when the queued workflow receives a runner.
- Then build P2.5–P2.6 from the same authoritative metadata without duplicating bounds or validation rules in UI code.

**Next logical task:**
- Verify the queued P2 test run, then implement the reusable numeric inspector control and warning presentation.

## 2026-09-01 — P2 bounded numeric control

**Phase/task IDs:** P2.5–P2.8

**Changed:**
- Added reusable `BoundedNumericControl` with the universal `LOW — THUMB — HIGH - [CURRENT]` layout.
- Bound slider hard limits and step directly to `TunablePropertySpec`/`RangeSpec` metadata.
- Used free numeric text entry for `[CURRENT]` so manual legal values are not quantized to slider step increments.
- Added warning-only presentation for values outside the recommended range, including consequence metadata.
- Added invalid-text handling that preserves the prior value.
- Added hard-bound clamping for breaking values.
- Documented the 12-decimal UI display precision constant and kept it display-only.
- Added focused headless editor-control tests and CI coverage.

**Validation actually run:**
- Earlier queued `tests/core/test_tunable_property_spec.gd` execution — PASS.
- Godot 4.7.2 project import — PASS.
- Godot project parse/check-only — PASS.
- P1 shared primitive regression suite — PASS.
- P2 metadata regression suite — PASS.
- Initial bounded-control test exposed a test lifecycle error; deferred assertions until the control reached `_ready()`.
- Second bounded-control run exposed two production issues: slider configuration could overwrite the caller-provided value, and approximate-equality display logic collapsed `0.000001` to `0`; both fixed.
- Final `tests/editor/test_bounded_numeric_control.gd` run — PASS.

**Result:**
- P2 complete.
- Data/runtime/editor ownership remains one-way: `BoundedNumericControl` consumes `TunablePropertySpec`; metadata and core primitives do not depend on editor code.
- Legal experimental values remain editable even when outside recommended bounds.

**New TODOs:**
- None required for P2. Later inspector/editor phases can reuse `BoundedNumericControl` rather than reinventing numeric bounds behavior.

**Next logical task:**
- Begin P3 constants and tuning infrastructure before the project model begins adding real project-level configuration.
