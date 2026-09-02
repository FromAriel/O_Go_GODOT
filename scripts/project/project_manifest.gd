class_name ProjectManifest
extends RefCounted

## Data-only description of one O Go GODOT game project.
##
## File parsing, validation, content lookup, and runtime instantiation deliberately
## live elsewhere so this object remains usable by code, tests, inspectors, and
## future authoring tools without pulling those systems together.

# Manifest schema contract. Version 1 is the only format currently supported.
# This is a serialization invariant rather than designer tuning; changing it
# requires an intentional schema/migration decision.
const CURRENT_SCHEMA_VERSION := 1

# Engine-supported base tile sizes for the MVP. These are discrete capability
# choices, not a numeric tuning range. Project authors choose among them in
# project data; adding another size requires verifying every tile-size-sensitive
# subsystem rather than merely widening a slider.
const SUPPORTED_TILE_SIZES := [16, 32, 64]

var schema_version: int = CURRENT_SCHEMA_VERSION
var project_id: StringName = &""
var title: String = ""
var project_version: String = ""
var tile_size: int = 32
var starting_map_id: StringName = &""
var starting_spawn_id: StringName = &""

# Explicit escape hatch for future/project-specific metadata. Core engine fields
# should still gain named schema entries when they become real supported features;
# this dictionary is not a substitute for designing those fields.
var extensions: Dictionary = {}


static func supports_tile_size(value: int) -> bool:
    return value in SUPPORTED_TILE_SIZES
