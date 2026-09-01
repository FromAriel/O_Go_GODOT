class_name StableId
extends RefCounted

## Human-readable stable identifier for project content.
##
## External data stores IDs as plain strings. This helper centralizes the
## convention without forcing serialized data to depend on a custom object.
## IDs are lowercase dot-separated namespaces such as `map.village` or
## `npc.village.blacksmith`. Each segment must be a valid GDScript-style
## identifier, must not begin with `_`, and must remain lowercase.

# Stable IDs require at least one namespace segment plus one local-name segment.
# This is a structural invariant, not tuning: there is no supported lower range
# below 2 because single-segment IDs lose namespace ownership. More segments are
# allowed without a fixed upper bound as long as every segment remains valid.
const MIN_SEGMENT_COUNT := 2

var value: StringName = &""


func _init(text: String = "") -> void:
    value = StringName(text)


func is_valid() -> bool:
    return is_valid_text(String(value))


func as_string() -> String:
    return String(value)


static func is_valid_text(text: String) -> bool:
    if text.is_empty() or text != text.to_lower():
        return false

    # Keep empty fields so malformed IDs such as `map..village` are rejected.
    var segments := text.split(".", true)
    if segments.size() < MIN_SEGMENT_COUNT:
        return false

    for segment in segments:
        if segment.is_empty():
            return false
        if segment.begins_with("_"):
            return false
        if not segment.is_valid_identifier():
            return false

    return true
