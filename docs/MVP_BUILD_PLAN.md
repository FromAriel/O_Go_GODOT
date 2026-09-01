# O Go GODOT — MVP Build Plan

## MVP Goal

Build a reusable Godot-based RPG construction system that proves the core engine and authoring architecture without trying to recreate all of RPG Maker at once.

The MVP is successful when we can create a game project, choose its tile scale, build a small map from tiles and props, move smoothly in eight directions, collide correctly, walk behind and in front of scenery, interact with an NPC and sign, transition between maps, and save/load state using a reusable engine structure rather than game-specific code.

---

## 1. Foundation — Separate Engine from Game Content

Keep `O_Go_GODOT` as the reusable engine/editor shell.

Establish a project-oriented structure conceptually like:

```text
engine/
projects/
  demo/
    project.json
    maps/
    tilesets/
    props/
    actors/
    dialogue/
    assets/
```

The engine must never assume there is only one game.

Each project manifest should contain at minimum:

```text
id
title
tile_size
movement_mode
starting_map
starting_position
```

Supported MVP tile sizes:

```text
16
32
64
```

Tile size is project configuration, not hardcoded engine behavior.

Automatic conversion of an existing 16/32/64 project between art scales is out of scope for MVP.

---

## 2. Minimal Project Loader

The engine must load a selected project.

For MVP, project selection may initially be a simple configured active project rather than a polished project browser.

Validate the project manifest and provide useful errors for:

- missing map
- invalid tile size
- missing asset
- invalid project ID
- malformed project data

The loader must be structured so a future New Project / Open Project UI can operate the same underlying system.

---

## 3. World and Map Model

Create a reusable map format containing:

- dimensions
- tile layers
- placed objects
- actors
- backdrop settings
- map metadata

Initial visual stack:

```text
WORLD BACKDROP
     ↓
BACKGROUND / PARALLAX
     ↓
LIQUID
     ↓
TERRAIN
     ↓
GROUND DECOR
     ↓
PROPS / STRUCTURES
     ↓
ACTORS
     ↓
OVERHANG / FOREGROUND
     ↓
WORLD VFX
     ↓
UI
```

Use Godot's native tilemap facilities where useful, while preserving our own semantic layer definitions so project data does not depend on arbitrary node ordering.

---

## 4. Tile System

Load a tileset belonging to the active project.

Support basic grid painting for:

- terrain
- water
- decoration
- blocked terrain

Tile dimensions must derive from the project's configured tile size.

Use a small placeholder/test tileset for MVP instead of spending time on polished art.

The design should remain compatible with ordinary external 16x16, 32x32, and 64x64 tile packs.

---

## 5. Eight-Direction Continuous Movement

Player movement is continuous world-space movement, not tile-to-tile movement.

Support eight directions with normalized diagonal speed.

The player uses a compact collision shape around the feet/body base rather than the full sprite bounds.

The camera follows the player smoothly.

Movement and sprite direction are separate concepts so four-direction art can still be used with eight-direction movement.

Anticipate both:

```text
4-way sprite direction
8-way sprite direction
```

Only one needs full polish for MVP.

---

## 6. Collision Model

Do not use pixel-perfect sprite alpha as the normal runtime collision system.

Terrain supports basic passable/blocked collision.

Props use explicit collision shapes independent of sprite dimensions.

Initial supported prop collision shapes:

- rectangle
- circle
- polygon

Fractional or sub-tile collision geometry should be possible where required.

A later editor convenience may generate suggested collision from image alpha, but that is not an MVP runtime rule.

---

## 7. Prop and Object System

Props are placed objects, not restricted to one tile.

A prop definition should support approximately:

```text
id
sprite
size
anchor
collision
animation
render_behavior
interaction
```

Placement modes should support:

```text
full tile
half tile
quarter tile
free
```

MVP examples should include enough variety to prove the model:

- tree
- barrel
- sign
- doorway or arch
- flower

One prop definition can be instantiated many times without duplicating the underlying art or behavior data.

---

## 8. Ground-Anchor Y Sorting

Actors and applicable props sort according to a ground-contact / feet anchor.

Walking behind a tree should place the actor behind its visible upper area; walking below the same tree should place the actor in front.

This must be generic behavior, not special-case tree logic.

The same sorting model should work for furniture, walls, statues, signs, NPCs, and similar world objects.

---

## 9. Foreground and Overhang Support

Props may optionally contain a foreground component.

Example:

```text
TREE
├── base/trunk
├── collision
└── canopy/overhang
```

This should support common RPG scenery such as:

- trees
- arches
- awnings
- roofs
- bridges
- cave entrances

MVP only needs one or two examples proving the system.

---

## 10. Animated World Objects

Animation belongs to object definitions rather than a single special animation layer.

Support looping frame animation with properties such as:

```text
frames
fps
loop
start_offset
randomized_phase
```

Demonstrate the system with examples such as:

- animated water
- swaying flower
- flickering or rotating prop

Random phase should prevent repeated decorations from animating in perfect synchronization.

---

## 11. Actor System

Create a common actor base:

```text
Actor
├── Player
└── NPC
```

Shared actor concepts include:

- position
- facing
- collision
- visual animation
- movement
- interaction area
- state

Do not build combat, stats, levels, or party systems yet.

NPC MVP behavior may include:

- stationary
- face player when interacted with
- optional simple wandering

---

## 12. Interaction System

Give the player a short interaction zone in the facing direction.

Interactable objects expose a standard interaction interface or event.

MVP examples:

```text
sign → display text
NPC → dialogue
door → change map or position
```

This system should later be reusable for shops, chests, switches, quest NPCs, gathering nodes, and crafting stations without implementing those systems now.

---

## 13. Minimal Dialogue System

MVP dialogue should support:

- speaker
- text
- multiple pages
- advance
- close

Dialogue must be stored as data rather than hardcoded directly into NPC scripts.

Out of scope for MVP:

- branching dialogue editor
- portraits
- conditions
- variables
- quest scripting
- localization tooling

---

## 14. Map Transitions

Support at least two maps.

A doorway or trigger should specify:

```text
destination_map
destination_spawn
```

Basic transition sequence:

```text
fade out
unload current map
load destination map
position player
fade in
```

This proves the engine supports a game world rather than a single scene.

---

## 15. Save and Load Foundation

Persist at minimum:

```text
active project
current map
player position
player facing
simple world-state dictionary
```

Reloading must restore the player to the expected state.

The save format should leave clean namespaces for future systems such as inventory, quests, party state, equipment, and progression.

Do not serialize arbitrary whole Godot nodes as game saves. Save intentional game state.

---

## 16. First Primitive Authoring Tools

The MVP does not need a complete standalone custom editor.

Initial authoring should support:

```text
select project
select/open map
paint tile layers
select prop
place prop
move/delete prop
view collision
place NPC
place interaction/transition
save
play-test
```

Lean on Godot editor tooling when it saves substantial implementation effort.

The critical rule is that editor operations must produce the same understandable project data that coding agents can modify directly.

---

## 17. Agent-Friendly Content Contract

Agent compatibility is a first-class architecture requirement.

Prefer stable IDs instead of fragile references where practical:

```text
map.village
prop.oak_tree
npc.innkeeper
dialogue.innkeeper_intro
```

Use:

- human-readable paths
- text-based manifests/resources where practical
- stable identifiers
- explicit relationships
- Git-friendly formats

Avoid an opaque proprietary database that only the editor understands.

Both workflows must ultimately manipulate the same project model:

```text
Human editor:
Drag an oak tree onto the map.

Agent:
"Put three oak trees beside the inn."
```

---

## 18. Demo Project / MVP Acceptance Scenario

Create one deliberately tiny playable demo containing:

```text
Meadow
  ↓
small pond
  ↓
flowers and trees
  ↓
little house
  ↓
NPC outside
  ↓
sign
  ↓
doorway
  ↓
HouseInterior
```

The player must be able to:

- move smoothly in eight directions
- collide with terrain and props
- walk behind and in front of trees
- see animated water
- see asynchronously animated flowers
- talk to an NPC
- read a sign
- enter the house
- return outside
- save
- quit
- load
- resume correctly

This is the MVP certification scenario.

---

# Explicitly Out of Scope for MVP

The architecture should leave room for these systems, but they should not block the first playable:

- combat
- stats
- levels and XP
- party management
- inventory
- equipment
- shops
- quests
- crafting
- loot tables
- advanced NPC AI/pathfinding
- day/night cycle
- weather simulation
- procedural maps
- sophisticated autotile authoring beyond inexpensive Godot-native capabilities
- advanced branching dialogue tooling
- cutscene timeline editor
- character creator
- large database editor
- export wizard
- mod support
- localization tooling
- multiplayer
- pixel-perfect collision generation
- automatic conversion of an existing project between 16/32/64 art scales
- fully polished standalone RPG-Maker-style application shell

---

# Recommended Build Order

```text
PROJECT MODEL
      ↓
MAP MODEL
      ↓
TILES + LAYERS
      ↓
PLAYER MOVEMENT
      ↓
COLLISION
      ↓
PROPS
      ↓
Y-SORT / OVERHANG
      ↓
ANIMATION
      ↓
ACTORS
      ↓
INTERACTION
      ↓
DIALOGUE
      ↓
MAP TRANSITIONS
      ↓
SAVE / LOAD
      ↓
AUTHORING TOOLS
      ↓
DEMO PROJECT
      ↓
MVP CERTIFICATION
```

Runtime and data contracts should stabilize before significant effort is spent building a custom editor UI.

---

# Architectural Invariant

The most important separation to preserve throughout development is:

```text
         O GO GODOT ENGINE
              │
              │ reads
              ▼
          PROJECT DATA
              ▲
             / \
            /   \
           /     \
      EDITOR     AGENT
      changes    changes
```

The editor is for humans.

The project data model is for both humans and agents.

The editor should remain friendly and visual without turning project data into an opaque black box that is hostile to code, Git, automation, or AI-assisted development.
