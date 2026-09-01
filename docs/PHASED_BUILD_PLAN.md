# O Go GODOT — Phased Implementation Plan

## Purpose

This document defines the stepwise construction order for the O Go GODOT engine/editor MVP. The existing vision and MVP build plan define **what** we are building; this document defines **the order in which we build it and the architectural rules each phase must obey**.

`CHECKLIST.md` is the terse execution ledger. It records completed phase tasks, validation actually run, newly discovered TODOs, and the next scoped action. Git remains the authoritative code history; the checklist is the human-readable phase history.

---

# Engineering Contract

These rules apply across every phase unless a later design decision explicitly replaces them.

## Separation of concerns

Every meaningful feature should be separable into four conceptual surfaces where applicable:

```text
DATA / DEFINITIONS
        ↓
DOMAIN / RUNTIME
        ↓
PRESENTATION
        ↓
EDITOR / INSPECTOR
```

Tests and validation observe these layers without becoming their owner.

The editor manipulates the same underlying project data that code, scripts, tests, and agents can manipulate. Important game state must never exist only inside an editor widget or opaque editor-only database.

## No monoliths

Prefer small, composable modules with a single clear responsibility.

Guidelines, not hard limits:

```text
100–600 lines     ideal focused module
600–1,200 lines   normal larger subsystem
~1,500 lines      review decomposition
~2,000 lines      strong decomposition warning
3,000+ lines      requires an explicit architectural reason
```

Generated tables, schemas, shaders, or other naturally large artifacts may exceed these sizes when justified. A giant manager class that owns unrelated systems is not justified merely because it is convenient.

Avoid generic junk drawers such as `GameManager`, `EverythingManager`, `Misc`, or `Helpers` unless the implementation truly has one narrow responsibility.

## Data-driven by default

Designer/gameplay values should live in data or well-defined resource/configuration objects whenever practical. Runtime code should consume definitions rather than embedding project-specific content.

The engine must not assume there is only one game project.

## Code and editor parity

Anything exposed in a useful inspector or editor must also remain directly alterable through source/project data. The visual tooling is a convenience surface over the same underlying model, not a second hidden model.

## Plan for future extension now, without building future systems now

Choose structures that leave clean attachment points for foreseeable features when doing so is cheap today:

- stable IDs
- versioned save structures
- semantic layers
- tags
- extension/custom-property dictionaries
- component-friendly definitions
- centralized property metadata
- explicit interfaces between input, movement, collision, rendering, and interaction

Do **not** prematurely build speculative infrastructure such as a custom scripting VM, network replication layer, full plugin ABI, or generic ECS merely because it might someday be useful.

## TODO philosophy

TODOs and placeholders preserve design intent; they are not law.

A TODO means:

> This is a foreseeable extension, unresolved question, or useful future direction worth recording.

It does **not** mean a future implementation must follow that exact idea. TODOs may be revised or deleted when later evidence suggests a better design.

Prefer scoped TODO labels where helpful:

```text
TODO(runtime)
TODO(editor)
TODO(data)
TODO(test)
TODO(future)
```

## Constants and magic-number policy

Unexplained magic numbers are not acceptable in runtime logic.

A legitimate constant should document, where relevant:

- what it controls
- why the value exists
- expected useful or safe bounds
- what changes or breaks if adjusted
- derivation/source when non-obvious

Example:

```gdscript
# Minimum squared velocity considered intentional movement.
# Prevents floating-point noise from changing actor facing.
# Expected useful range: 1e-10 .. 1e-4.
# Larger values make very slow movement inputs appear stationary.
const FACING_INPUT_EPSILON_SQ := 1e-8
```

Prefer named configuration over constants when designers should reasonably tune the value.

---

# Universal Tunable-Value Contract

Numeric values exposed to users/designers should use one shared metadata and UI model.

## Numeric control presentation

The default visual grammar is:

```text
LOW BOUND -------- THUMB -------- HIGH BOUND - [CURRENT]
```

The current value is directly editable in addition to the slider/thumb.

Example:

```text
Run Speed
0.000001 -----------●---------------- 12000 - [8000]
```

## Recommended bounds vs. hard bounds

Definitions should distinguish:

1. **Recommended range** — conventional/useful values.
2. **Legal exploration range** — values the engine supports even if gameplay becomes strange.
3. **Breaking/invalid range** — values the system cannot safely support.

A designer may freely explore legal values outside the recommended range.

Example:

```text
run_speed:
  value: 300
  default: 300
  recommended_min: 80
  recommended_max: 700
  hard_min: 0.000001
  hard_max: 12000
  step: 1
  unit: pixels_per_second
  description: Player movement velocity while running.
  rationale: Values around 250–450 produce conventional JRPG movement.
  consequences: Extremely high values may appear to teleport and may expose collision limitations.
```

The inspector must read these bounds from the authoritative property metadata rather than duplicating them in UI code.

Outside the recommended range, warn but do not block. Outside the legal hard range, reject or clamp according to the property contract.

This shared model should eventually drive movement, animation, camera, audio, encounter rates, weather, VFX, damage, lighting, and other tunable systems.

---

# Phase 0 — Governance and execution contract

Establish the development rules before adding gameplay systems.

### Deliverables

- Maintain the document hierarchy:
  - vision document — long-lived product direction
  - `docs/MVP_BUILD_PLAN.md` — MVP systems and feature intent
  - `docs/PHASED_BUILD_PLAN.md` — dependency-aware execution order
  - `CHECKLIST.md` — terse implementation ledger
- Record the separation-of-concerns, data-driven, module-size, TODO, constants, validation, and tunable-value policies.
- Ensure every implementation turn updates `CHECKLIST.md` with the scoped work actually performed.

### Phase exit

The repository has clear architectural and execution rules, and subsequent work can be referenced by stable phase/task IDs.

---

# Phase 1 — Shared primitives and diagnostics

Create the small set of concepts many later systems need without turning them into a framework.

### Candidate primitives

- `StableId`
- `Bounds` / `RangeSpec`
- `WorldPosition`
- `GridPosition`
- `Direction`
- `AssetReference`
- `ValidationResult`
- `Diagnostic`

### Stable ID convention

Human-readable project content identifiers should support patterns such as:

```text
map.village
map.village_inn
actor.player
npc.village.blacksmith
prop.tree.oak
prop.sign.wood
dialogue.blacksmith.intro
```

IDs must survive file moves/renames whenever practical.

### Diagnostic contract

Use a common structure such as:

```text
severity
code
message
source
field
suggested_fix
```

The same diagnostics should eventually be displayable by runtime, CI, and editor tooling.

### Phase exit

Shared primitives are focused, documented, tested where appropriate, and can be consumed without importing unrelated engine systems.

---

# Phase 2 — Universal property metadata and bounded controls

Build the authoritative metadata model for user/designer-editable values before movement and other systems begin defining incompatible tuning rules.

### Deliverables

- reusable property/range metadata definition
- recommended and hard bounds
- defaults, step size, units, description, rationale, consequences
- validation behavior
- reusable numeric editor/inspector control using the universal format
- warnings for legal-but-unusual values
- tests for boundary conditions

### Phase exit

Several representative dummy settings can be edited through the same generic control and validated from the same metadata used by code.

---

# Phase 3 — Constant/tuning infrastructure

Apply the magic-number policy structurally.

### Deliverables

- conventions for project configuration vs. runtime constants
- centralized tunable definitions where appropriate
- documentation expectations for non-obvious constants
- lint/review guidance for unexplained literals in critical runtime logic

### Phase exit

New gameplay/runtime systems have an obvious place for designer-tunable values and a documented rule for legitimate constants.

---

# Phase 4 — Project model

Establish the reusable engine/game separation.

### Conceptual ownership

```text
engine/
  runtime/
  editor/
  shared/

projects/
  demo/
    project data
    maps/
    actors/
    props/
    dialogue/
    assets/
```

The exact directory layout may evolve; ownership boundaries should remain clear.

### Project manifest should anticipate

```text
identity
  id
  title
  version

world
  tile_size
  starting_map
  starting_spawn

movement
  directional_mode
  defaults

rendering
  base_resolution
  sorting

content
  map_paths
  actor_paths
  prop_paths

future extension points
  localization
  plugins
  game_rules
  export_profile
```

Future sections need not be implemented yet.

### Tile scale

Support project-level 16, 32, and 64 pixel base tiles, with 32 as the initial default. No downstream system may quietly hardcode 32.

### Validation

Produce understandable diagnostics for invalid manifests, duplicate IDs, unsupported values, broken references, and missing starting content.

### Phase exit

A minimal game project loads through the project model rather than game-specific hardcoding.

---

# Phase 5 — Content registry and reference resolution

Build the resolver that connects stable project IDs to definitions/resources.

### Responsibilities

- register content definitions
- resolve stable IDs
- detect duplicates
- validate missing references
- support editor search/reference pickers later

### Non-responsibility

The registry locates content; it does not instantiate gameplay objects.

### Future attachment points

The design should not block future asset packs, mods, project inheritance, renaming tools, or reference migration.

### Phase exit

Maps, props, actors, dialogue, and assets can be addressed by stable IDs with focused diagnostics.

---

# Phase 6 — Map data model

Define maps as data before rendering them richly.

### Map structure should anticipate

- identity
- dimensions
- environment
- semantic layers
- placed objects
- actors
- triggers
- spawn points
- metadata
- extension/custom fields

### Semantic layers

Core semantic roles include:

```text
backdrop
background
liquid
terrain
ground_decor
world_objects
actors
overhang
world_vfx
```

Do not make this fixed list an irreversible enum; future/custom layers should be possible.

### Serialization

Add load/save round-trip tests for meaningful map state.

### Phase exit

Map data can be loaded, validated, serialized, and reloaded without depending on a rendered Godot scene as the authority.

---

# Phase 7 — Tile terrain rendering

Render the map model using Godot's tile facilities without surrendering authority to scene-node layout.

### MVP rendering

- terrain
- ground decoration
- water/liquid
- basic animated tiles
- deliberately small developer tileset

### Rule

All tile geometry derives from `project.tile_size`.

### Separation

```text
MapData
  ↓
MapRuntime
  ↓
TileLayerRenderer
```

### Phase exit

A data-defined test map renders correctly at the supported project tile scales.

---

# Phase 8 — Collision infrastructure

Create shared spatial collision before sophisticated movement.

### Tile collision

Initially support:

- none
- full
- rectangle
- polygon

### Prop collision

Collision is independent from sprite bounds. A large tree may have only a small trunk collider.

### Debug infrastructure

Build reusable spatial debug drawing for colliders, anchors, interaction ranges, and later navigation regions.

### Phase exit

Static world geometry collides predictably and collision/debug data is inspectable.

---

# Phase 9 — Actor foundation

Create the common movable-world-object contract without stuffing every future RPG system into it.

### Shared actor concerns

- identity
- position
- facing
- velocity/movement state
- collision
- visual state
- interaction presence

### Future actors

```text
Actor
├── Player
├── NPC
├── Enemy      [future]
├── Animal     [future]
└── MovingObject [future]
```

Inventory, quests, shops, combat, equipment, and dialogue trees do not belong in the base actor merely because some actor types may eventually use them.

### Phase exit

Player and simple NPC actor types can share the actor foundation without unrelated coupling.

---

# Phase 10 — Movement system

Implement continuous eight-direction movement with input separated from movement physics.

### Pipeline

```text
Input / AI / Script
       ↓
MovementIntent
       ↓
ActorMotor
       ↓
Collision
       ↓
Position
```

This separation should allow later keyboard, controller, NPC AI, cutscene, pathfinding, replay, or networking sources to drive the same motor.

### Requirements

- eight-direction continuous movement
- normalized diagonal speed
- configurable acceleration/deceleration where useful
- four-way art usable with eight-way physical movement
- inspector-backed movement settings using universal bounds metadata

### Phase exit

The player moves smoothly through collision geometry in all eight directions using data-driven tuning.

---

# Phase 11 — Camera system

Keep camera behavior separate from the player actor.

### MVP

- target following
- offset
- smoothing
- bounds

### Future placeholders

- look-ahead
- shake
- cinematic targets
- zoom regions
- dead zones
- multi-target framing

### Phase exit

The camera can follow/switch targets without actor code owning camera behavior.

---

# Phase 12 — Props and placed world objects

Create reusable object definitions independent of the tile grid.

### Prop definition should anticipate

- identity
- visual definition
- transform
- anchor
- collision
- sorting
- animation
- interaction
- tags
- custom properties / future components

### Placement

Editor-side snapping should support tile, half-tile, quarter-tile, eighth-tile, and free placement. Snap behavior is an authoring convenience, not a runtime constraint.

### MVP examples

- tree
- barrel
- sign
- flower
- archway

### Phase exit

Reusable prop definitions can be instantiated multiple times with independent transforms/state.

---

# Phase 13 — Spatial sorting and overhangs

Implement classic JRPG depth behavior as a focused rendering concern.

### Ground anchors

Actors and sortable props expose a ground-contact anchor. Depth ordering uses anchor world Y rather than raw sprite bounds.

### Overhangs

Objects may optionally separate base and foreground/overhang visuals.

### Acceptance examples

- walk behind a tree
- walk in front of the same tree
- pass beneath an arch/overhang

### Phase exit

Depth behavior is generic and requires no tree-specific or NPC-specific sorting logic.

---

# Phase 14 — Animation subsystem

Animation is an object capability, not a single special map layer.

### Initial definition

- frames
- FPS
- loop
- phase/start offset
- random start
- playback mode

### Future extension points

- state machines
- event markers
- one-shot playback
- ping-pong
- conditional animation

### MVP examples

- water
- swaying flower
- torch/spinning prop

### Phase exit

Reusable definitions animate independently, including randomized phase where configured.

---

# Phase 15 — Interaction framework

Create a generic interaction pipeline before dialogue.

```text
Interactor
   ↓
InteractionQuery
   ↓
Interactable
   ↓
InteractionAction
```

### MVP actions

- show text
- talk
- transition

### Future actions

- shop
- loot
- harvest
- activate
- craft
- inspect
- quest
- combat

Avoid central type-switch monsters such as `if object is NPC ... else if chest ...`.

### Phase exit

The player can trigger different interaction actions through one reusable framework.

---

# Phase 16 — Dialogue MVP

Dialogue lives in structured external data and uses its own presentation layer.

### MVP

- speaker
- text
- multiple pages
- advance
- close

### Schema should anticipate without implementing

- conditions
- choices
- variables
- commands
- portraits
- localization keys
- voice

NPCs reference dialogue definitions; NPC scripts do not become dialogue engines.

### Phase exit

NPC/sign interactions can display data-defined dialogue/text without hardcoded conversation content.

---

# Phase 17 — Map transitions and world routing

Introduce focused world-routing concepts.

### Core definitions

- `SpawnPoint`
- `Transition`
- `MapRouter`

A transition references a destination map and named spawn rather than embedding arbitrary destination coordinates wherever practical.

### MVP proof

`Meadow → House → Meadow`

### Phase exit

Map changes are data-defined, validated, and reusable.

---

# Phase 18 — State model and save/load

Create intentional, versioned save state rather than serializing arbitrary Godot scene trees.

### Structure should anticipate

```text
SaveState
├── metadata
├── player
├── world
├── maps
├── actors
├── flags
├── inventory   [future]
├── quests      [future]
└── custom      [future]
```

Add save-version/migration scaffolding from the first format even if migration v1 is initially trivial.

### Phase exit

The player can save, quit, reload, and restore the intended MVP state through explicit versioned data.

---

# Phase 19 — Inspector/editor foundation

Only after the runtime contracts are proven should substantial RPG-Maker-like tooling become authoritative user experience.

### Reusable editor controls

- stable-ID selector
- asset picker
- universal numeric bounded control
- vector/position control
- collision editor/viewer
- tag editor
- reference picker
- validation/diagnostic display

### Numeric control requirements

```text
LOW -------- THUMB -------- HIGH - [CURRENT]
```

Support manual input, units, recommended range indication, hard-range validation, help/rationale, consequences, and reset-to-default.

### Phase exit

Core project definitions can be edited usefully without hiding or duplicating their underlying data model.

---

# Phase 20 — Map authoring tools

Build the first functional RPG-Maker-like map editing surface.

### Minimum operations

- select/open map
- select semantic layer
- paint/erase tiles
- place/move/delete props
- place actors
- place spawn points
- place transitions
- toggle collision overlay
- toggle anchors/debug overlays
- save
- play-test

No shadow editor database is permitted; operations modify normal project data/resources.

### Phase exit

A user can construct the MVP test map through functional visual tooling rather than hand-editing all map content.

---

# Phase 21 — Project creation UI

Expose the project system visually using the same creation service available to code/scripts.

### MVP fields

- name
- stable ID
- tile size: 16 / 32 / 64
- movement mode: four-way/eight-way presentation choice
- starting map

### Rule

GUI, CLI/scripts, tests, and AI agents should ultimately be equal clients of the underlying project services.

### Phase exit

A user can create/open a project without manually assembling its manifest.

---

# Phase 22 — Demo project assembly

Assemble the complete MVP acceptance world from the systems already built.

### Meadow

- grass/terrain
- water
- flowers
- trees
- sign
- NPC
- house

### House

- floor/walls
- furniture/props
- doorway/transition

### Acceptance chain

```text
launch project
↓
load meadow
↓
move eight-directionally
↓
collide with terrain/props
↓
walk behind/in front of tree
↓
observe animated water/flowers
↓
read sign
↓
talk to NPC
↓
enter house
↓
return outside
↓
save
↓
quit
↓
load
↓
restore intended state
```

### Phase exit

The full MVP vertical slice works end-to-end through the reusable engine/project architecture.

---

# Phase 23 — Hardening and MVP certification

Test failure modes and extreme-but-legal configuration values after the vertical slice works.

### Audit areas

- reference validation
- missing/bad assets
- malformed project/map data
- duplicate IDs
- save corruption/version handling
- tile size 16
- tile size 32
- tile size 64
- collision edge cases
- failed map transitions
- extreme legal configuration values

If `run_speed = 8000` is within declared hard bounds, gameplay may look absurd, but the engine should not fail structurally. If a value genuinely breaks engine safety, the declared hard bound is wrong.

### Phase exit

The MVP acceptance scenario and targeted failure/extreme-value tests pass with documented evidence.

---

# Phase 24 — Architecture review before feature expansion

Pause before adding inventory, combat, quests, shops, or other major RPG systems.

### Audit specifically for

- oversized modules
- circular dependencies
- God objects
- duplicate schemas
- editor/runtime coupling
- hardcoded tile-size assumptions
- hardcoded map assumptions
- prop/NPC special cases
- unexplained constants
- poor diagnostics
- serialization traps
- extension points that proved awkward in real use

Fix structural problems while the feature surface is still small.

### Phase exit

Architecture is judged ready for independent post-MVP feature lanes.

---

# Post-MVP Feature Lanes

After certification and architecture review, development may split into relatively independent tracks.

## RPG systems

- inventory
- items
- equipment
- stats
- XP/levels
- party

## World systems

- weather
- day/night
- zones
- environmental effects
- pathfinding
- NPC schedules

## Narrative

- branching dialogue
- quests
- cutscenes
- conditions
- variables

## Combat

- encounters
- abilities
- status effects
- AI

## Authoring

- database editors
- animation editor
- dialogue editor
- quest editor
- tileset tooling

## Pipeline

- export
- asset packs
- plugins
- mods
- localization

The MVP should leave clean attachment points for these. It should not contain half-built implementations merely to claim future compatibility.

---

# Dependency Summary

```text
P0  Governance / engineering contract
 ↓
P1  Shared primitives / diagnostics
 ↓
P2  Property metadata / bounded controls
 ↓
P3  Constants / tuning infrastructure
 ↓
P4  Project model
 ↓
P5  Content registry
 ↓
P6  Map model
 ↓
P7  Tile rendering
 ↓
P8  Collision
 ↓
P9  Actor foundation
 ↓
P10 Movement
 ↓
P11 Camera
 ↓
P12 Props
 ↓
P13 Y-sort / overhang
 ↓
P14 Animation
 ↓
P15 Interaction
 ↓
P16 Dialogue
 ↓
P17 Map routing
 ↓
P18 Save state
 ↓
P19 Inspector/editor foundation
 ↓
P20 Map authoring
 ↓
P21 Project creation UI
 ↓
P22 Demo project
 ↓
P23 Hardening / certification
 ↓
P24 Architecture review
 ↓
POST-MVP FEATURE LANES
```

---

# Core Architectural Invariant

The project must preserve this relationship throughout development:

```text
               O GO GODOT ENGINE
                      │
                      │ reads / writes through defined services
                      ▼
                 PROJECT DATA
                  ▲        ▲
                 /          \
                /            \
          EDITOR / UI      CODE / AGENT
```

The editor is for humans. The data model and source remain equally accessible to humans, scripts, tests, and coding agents.

The engine should tell designers what values are sensible, tell them what values are safe, allow experimentation throughout safe space, and document why defaults/constants exist.