class_name ContentRegistry
extends RefCounted

## Stable-ID registry for locating project content definitions.
##
## Responsibilities:
## - register validated content descriptors
## - resolve stable IDs and AssetReference values
## - detect duplicate IDs
## - diagnose missing/kind-mismatched references
## - expose deterministic descriptor listing for future editor search/pickers
##
## Non-responsibility: this class never loads scenes, constructs Nodes, or
## instantiates gameplay/domain objects. Callers decide what to do with a found
## ContentDefinition after resolution.

var _definitions: Dictionary = {}


func register_definition(definition: ContentDefinition, source: String = "") -> ValidationResult:
    var validation := ValidationResult.new()
    if definition == null:
        validation.add_error(
            &"content.registry.null_definition",
            "Cannot register a null content definition.",
            source,
            &"definition",
            "Provide a ContentDefinition before registration."
        )
        return validation

    var id_text := definition.id_text()
    var kind_text := definition.kind_text()

    if not StableId.is_valid_text(id_text):
        validation.add_error(
            &"content.registry.invalid_id",
            "Content id '%s' is not a valid stable ID." % id_text,
            source,
            &"content_id",
            "Use a lowercase dot-separated stable ID such as 'map.meadow'."
        )

    if not _is_valid_kind(kind_text):
        validation.add_error(
            &"content.registry.invalid_kind",
            "Content kind '%s' is invalid." % kind_text,
            source,
            &"kind",
            "Use a lowercase identifier such as 'map', 'actor', or 'dialogue'."
        )
    elif StableId.is_valid_text(id_text) and not id_text.begins_with(kind_text + "."):
        validation.add_error(
            &"content.registry.kind_namespace",
            "Content id '%s' does not match declared kind '%s'." % [id_text, kind_text],
            source,
            &"kind",
            "Use the content kind as the stable-ID namespace prefix."
        )

    if _definitions.has(definition.content_id):
        var existing: ContentDefinition = _definitions[definition.content_id]
        validation.add_error(
            &"content.registry.duplicate_id",
            "Duplicate content id '%s' is already registered from '%s'."
                % [id_text, existing.source_path],
            source,
            &"content_id",
            "Give each content definition a unique stable ID or remove the duplicate."
        )

    if validation.has_errors():
        return validation

    _definitions[definition.content_id] = definition
    return validation


func register_all(definitions: Array, source: String = "") -> ValidationResult:
    var combined := ValidationResult.new()
    for definition in definitions:
        combined.merge(register_definition(definition, source))
    return combined


func resolve_id(
    content_id: StringName,
    expected_kind: StringName = &"",
    source: String = ""
) -> ContentLookupResult:
    var result := ContentLookupResult.new()
    var id_text := String(content_id)

    if not StableId.is_valid_text(id_text):
        result.validation.add_error(
            &"content.registry.invalid_reference",
            "Content reference '%s' is not a valid stable ID." % id_text,
            source,
            &"content_id",
            "Use a valid stable content ID."
        )
        return result

    if not _definitions.has(content_id):
        result.validation.add_error(
            &"content.registry.missing_reference",
            "No content definition is registered for '%s'." % id_text,
            source,
            &"content_id",
            "Add/register the referenced content or correct the stable ID."
        )
        return result

    result.definition = _definitions[content_id]

    var expected_text := String(expected_kind)
    if not expected_text.is_empty():
        if not _is_valid_kind(expected_text):
            result.validation.add_error(
                &"content.registry.invalid_expected_kind",
                "Expected content kind '%s' is invalid." % expected_text,
                source,
                &"expected_kind",
                "Use a lowercase identifier for the expected kind."
            )
        elif result.definition.kind != expected_kind:
            result.validation.add_error(
                &"content.registry.kind_mismatch",
                "Content '%s' is kind '%s', not expected kind '%s'."
                    % [id_text, result.definition.kind_text(), expected_text],
                source,
                &"expected_kind",
                "Reference content with the expected kind or correct the reference metadata."
            )

    return result


func resolve_reference(reference: AssetReference, source: String = "") -> ContentLookupResult:
    if reference == null or not reference.is_valid():
        var invalid := ContentLookupResult.new()
        invalid.validation.add_error(
            &"content.registry.invalid_reference",
            "Asset/content reference is empty or invalid.",
            source,
            &"content_id",
            "Provide a valid stable content ID."
        )
        return invalid

    return resolve_id(StringName(reference.content_id), reference.expected_kind, source)


func contains_id(content_id: StringName) -> bool:
    return _definitions.has(content_id)


func size() -> int:
    return _definitions.size()


func all_definitions() -> Array[ContentDefinition]:
    var entries: Array[ContentDefinition] = []
    for definition in _definitions.values():
        entries.append(definition)
    entries.sort_custom(func(a: ContentDefinition, b: ContentDefinition) -> bool:
        return a.id_text() < b.id_text()
    )
    return entries


static func _is_valid_kind(value: String) -> bool:
    return (
        not value.is_empty()
        and value == value.to_lower()
        and not value.begins_with("_")
        and value.is_valid_identifier()
    )
