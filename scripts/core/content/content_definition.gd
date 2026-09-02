class_name ContentDefinition
extends RefCounted

## Data-only registry entry for one stable piece of project content.
##
## The registry stores descriptors, not instantiated gameplay objects. Future
## map/actor/prop/dialogue/resource loaders may use `source_path` and `metadata`
## after lookup, but construction remains outside the registry itself.

var content_id: StringName = &""
var kind: StringName = &""
var source_path: String = ""
var metadata: Dictionary = {}


func _init(
    p_content_id: StringName = &"",
    p_kind: StringName = &"",
    p_source_path: String = "",
    p_metadata: Dictionary = {}
) -> void:
    content_id = p_content_id
    kind = p_kind
    source_path = p_source_path
    metadata = p_metadata.duplicate(true)


func id_text() -> String:
    return String(content_id)


func kind_text() -> String:
    return String(kind)
