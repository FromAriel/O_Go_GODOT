class_name AssetReference
extends Resource

## Serializable reference to project content/assets.
##
## `content_id` is the durable identity used by future registries. `path_hint`
## is optional discovery/debug context and must never become the authoritative
## identity. `expected_kind` allows future resolvers/editors to reject obviously
## wrong reference types without hard-coding content-specific logic here.

const StableIdType = preload("res://scripts/core/ids/stable_id.gd")

@export var content_id: String = ""
@export var expected_kind: StringName = &""
@export_file var path_hint: String = ""


func is_empty() -> bool:
    return content_id.is_empty()


func is_valid() -> bool:
    return not is_empty() and StableIdType.is_valid_text(content_id)
