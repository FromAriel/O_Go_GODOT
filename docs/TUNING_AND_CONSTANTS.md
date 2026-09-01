# O Go GODOT — Tuning, Configuration, and Constants Policy

This document defines where adjustable values belong and when a numeric or textual constant is justified.

The goal is simple: **designer/user choices stay data-driven, engine invariants stay explicit, and unexplained magic values do not accumulate in code.**

This policy guides implementation; it is not a reason to build speculative infrastructure before a real system needs it.

---

## 1. Value ownership categories

### A. User/designer-editable values

If a value is meaningfully adjustable by a project author or player-facing tool, it is **data**, not an engine constant.

Examples:

- movement speed
- acceleration/deceleration
- animation FPS
- camera smoothing
- encounter rate
- interaction distance
- particle count
- light intensity

Numeric tunables use `TunablePropertySpec` for authoritative metadata:

- default
- hard bounds
- recommended bounds
- step
- unit
- description
- rationale
- consequences

The actual current value belongs to the owning project/content/runtime data object. Do not create a global singleton merely to hold every tunable.

### B. Project configuration

Values that define how a whole game project behaves belong to the project model introduced in P4.

Examples:

- tile size
- starting map/spawn
- movement presentation mode
- base resolution
- project-specific defaults

Project configuration must remain editable both in code/text data and through useful inspectors/UI where appropriate.

### C. Content-local configuration

Values that belong to one map, actor, prop, animation, dialogue item, etc. stay with that content definition rather than moving into a global tuning file.

Examples:

- one NPC's wander radius
- one prop's collision footprint
- one animation's playback rate
- one map's ambient settings

Centralize definitions only when several systems genuinely share the same semantic setting.

### D. Engine/runtime invariants

A code constant is appropriate when changing the value would change an invariant, protocol, mathematical identity, structural rule, or implementation contract rather than merely tune gameplay.

Examples:

- `1 / sqrt(2)` for normalized 45-degree diagonal components
- required namespace segment count for stable IDs
- serialization format/version identifiers
- fixed bit masks or protocol markers

These values should not be exposed as ordinary designer settings.

### E. Presentation-only constants

Local named constants are appropriate for editor/UI implementation details that are not game data.

Examples:

- a minimum input-field width
- display precision
- editor-only layout thresholds

Keep these local to the control/module that owns them. Do not create a global UI-constants monolith unless several independent controls actually need the same design token.

### F. Derived values

If a value can be derived reliably from authoritative data, derive it instead of storing another copy.

Examples:

- world pixel position from grid position and project tile size
- normalized diagonal vector from direction
- warning state from current value and `RangeSpec`

Avoid duplicate authorities.

---

## 2. No global tuning junk drawer

Do not create an `EverythingConstants`, `GlobalTuning`, `GameSettings`, or similar catch-all object.

Preferred ownership:

```text
project-wide choice     -> project configuration
content-specific choice -> content definition
numeric metadata        -> TunablePropertySpec
engine invariant        -> local named constant
shared semantic setting -> focused domain resource/service
```

Centralization is useful only when it represents **shared ownership**, not merely because values are numbers.

---

## 3. Documentation contract for non-obvious constants

A non-obvious constant or critical literal must make the following discoverable near its definition:

1. **What** the value controls.
2. **Why** the value deserves to exist in code instead of project/content data.
3. **Expected range or invariant.**
   - If tunable in principle, document useful/safe bounds.
   - If mathematically or structurally fixed, explicitly say there is no tuning range and state the invariant.
4. **Consequence of change.** Explain what becomes incorrect, degraded, or merely different.
5. **Source/derivation** when the value comes from math, a format, external specification, or measured constraint.

Example:

```gdscript
# Exact component of a normalized 45-degree diagonal: 1 / sqrt(2).
# Invariant, not tuning: there is no supported operating range; changing this
# makes diagonal direction vectors non-unit length.
const DIAGONAL_COMPONENT := 0.7071067811865476
```

For an editor-only value:

```gdscript
# Minimum width for the bracketed numeric entry field. 120 px keeps typical
# signed/decimal values readable without dominating the row.
# Expected useful UI range: roughly 80–240 px. Smaller widths truncate common
# values; larger widths waste horizontal inspector space.
const CURRENT_VALUE_MIN_WIDTH := 120.0
```

---

## 4. What does not need ceremonial documentation

Do not turn this policy into comment noise.

Ordinary language/runtime idioms generally do not need named constants merely because they contain a number:

- `0`, `1`, or `-1` when their meaning is obvious from the operation
- loop/index increments
- `Vector2.ZERO`, `Vector2.UP`, etc.
- enum ordinal mechanics
- test input values whose purpose is clear from the test name/assertion

If a reviewer has to ask "why *that* number?", it probably deserves a name or explanation.

---

## 5. Bounds philosophy

For user-editable numeric values, distinguish:

```text
recommended range  -> likely to produce sensible gameplay
hard/legal range   -> engine promises to accept the value safely
invalid range      -> rejected or clamped according to the owning API
```

A value outside the recommendation but inside hard bounds remains legal.

Example:

```text
Run Speed
0.000001 -------- Thumb -------- 12000 - [8000]

Recommended: 80–700
Legal:       0.000001–12000
```

The engine may warn that 8000 will look like teleportation; it should not forbid it merely for being odd.

---

## 6. Inspector/code parity

The UI must read the same metadata/runtime rules that code uses.

Do not duplicate bounds, defaults, units, rationale, or warning thresholds inside editor widgets.

```text
TunablePropertySpec
       |\
       | \-> runtime validation
       |\
       | \-> inspector presentation
       |
       \----> documentation/tooltips
```

A user or coding agent editing the underlying data and a user editing through the GUI must be operating on the same semantic model.

---

## 7. Review checklist for new values

When adding a significant literal or constant, ask:

- Could a project author reasonably want to change this?
  - If yes, it probably belongs in data/configuration.
- Is it specific to one content object?
  - Keep it with that object.
- Is it derived from another authority?
  - Derive it rather than storing it twice.
- Is it a true engine invariant?
  - Use a named local constant and document the invariant.
- Is it only a local editor/presentation choice?
  - Use a named local constant with expected UI bounds when non-obvious.
- Would centralizing it create a junk-drawer dependency?
  - Leave it with its owning subsystem.

TODOs may note future centralization or tooling opportunities, but they are guidance, not commitments.

---

## 8. Enforcement level for MVP

For the MVP, this is primarily a code-review and agent-development rule, reinforced by `AGENTS.md` and `CHECKLIST.md`.

We are intentionally **not** adding a naive numeric-literal linter in P3. Such a linter would flag harmless indexes, vectors, tests, and format code while missing semantic mistakes. If the codebase grows enough that an AST-aware review tool becomes worthwhile, add it later as a focused TODO/tooling task rather than treating today's absence as architectural debt.
