class_name ProjectManifestValidator
extends RefCounted

## Decodes manifest-shaped data and applies structural + semantic validation.
##
## This layer intentionally knows the manifest schema but does not perform file
## I/O and does not resolve map/spawn references. P5 will own content resolution.

const ROOT_FIELDS := ["schema_version", "id", "title", "version", "world", "extensions"]
const WORLD_FIELDS := ["tile_size", "starting_map", "starting_spawn"]


static func decode(data: Variant, source: String = "") -> ProjectLoadResult:
    var load_result := ProjectLoadResult.new()
    load_result.source_path = source
    var validation := load_result.validation

    if typeof(data) != TYPE_DICTIONARY:
        validation.add_error(
            &"project.manifest.root_type",
            "Project manifest root must be an object/dictionary.",
            source,
            &"manifest",
            "Use a JSON object at the root of the manifest."
        )
        return load_result

    var root: Dictionary = data
    _warn_unknown_fields(root, ROOT_FIELDS, validation, source, "")

    var schema_version = _read_required_integer(
        root, "schema_version", validation, source, &"schema_version"
    )
    var project_id = _read_required_string(root, "id", validation, source, &"id")
    var title = _read_required_string(root, "title", validation, source, &"title")
    var project_version = _read_required_string(
        root, "version", validation, source, &"version"
    )

    var world_value = _read_required_dictionary(root, "world", validation, source, &"world")
    var tile_size = null
    var starting_map = null
    var starting_spawn = null
    if world_value != null:
        var world: Dictionary = world_value
        _warn_unknown_fields(world, WORLD_FIELDS, validation, source, "world.")
        tile_size = _read_required_integer(
            world, "tile_size", validation, source, &"world.tile_size"
        )
        starting_map = _read_required_string(
            world, "starting_map", validation, source, &"world.starting_map"
        )
        starting_spawn = _read_required_string(
            world, "starting_spawn", validation, source, &"world.starting_spawn"
        )

    var extensions: Dictionary = {}
    if root.has("extensions"):
        if typeof(root["extensions"]) != TYPE_DICTIONARY:
            validation.add_error(
                &"project.manifest.extensions_type",
                "Manifest 'extensions' must be an object/dictionary when present.",
                source,
                &"extensions",
                "Use an object for extension metadata or remove the field."
            )
        else:
            extensions = (root["extensions"] as Dictionary).duplicate(true)

    if validation.has_errors():
        return load_result

    var manifest := ProjectManifest.new()
    manifest.schema_version = int(schema_version)
    manifest.project_id = StringName(project_id)
    manifest.title = title
    manifest.project_version = project_version
    manifest.tile_size = int(tile_size)
    manifest.starting_map_id = StringName(starting_map)
    manifest.starting_spawn_id = StringName(starting_spawn)
    manifest.extensions = extensions
    load_result.manifest = manifest

    _validate_semantics(manifest, validation, source)
    return load_result


static func _validate_semantics(
    manifest: ProjectManifest,
    validation: ValidationResult,
    source: String
) -> void:
    if manifest.schema_version != ProjectManifest.CURRENT_SCHEMA_VERSION:
        validation.add_error(
            &"project.manifest.schema_version",
            "Unsupported project manifest schema version %d; this engine supports version %d."
                % [manifest.schema_version, ProjectManifest.CURRENT_SCHEMA_VERSION],
            source,
            &"schema_version",
            "Use a supported manifest version or migrate the project data."
        )

    var project_id_text := String(manifest.project_id)
    if not StableId.is_valid_text(project_id_text) or not project_id_text.begins_with("project."):
        validation.add_error(
            &"project.manifest.id",
            "Project id must be a valid stable ID in the 'project.' namespace.",
            source,
            &"id",
            "Use an ID such as 'project.my_game'."
        )

    if manifest.title.strip_edges().is_empty():
        validation.add_error(
            &"project.manifest.title",
            "Project title must not be empty.",
            source,
            &"title",
            "Provide a human-readable project title."
        )

    if manifest.project_version.strip_edges().is_empty():
        validation.add_error(
            &"project.manifest.version",
            "Project version must not be empty.",
            source,
            &"version",
            "Provide a project version string such as '0.1.0'."
        )

    if not ProjectManifest.supports_tile_size(manifest.tile_size):
        validation.add_error(
            &"project.manifest.tile_size",
            "Unsupported tile size %d. Supported project tile sizes are %s."
                % [manifest.tile_size, str(ProjectManifest.SUPPORTED_TILE_SIZES)],
            source,
            &"world.tile_size",
            "Choose 16, 32, or 64 for the MVP."
        )

    _validate_typed_stable_id(
        String(manifest.starting_map_id),
        "map.",
        &"project.manifest.starting_map",
        &"world.starting_map",
        "starting map",
        "map.meadow",
        validation,
        source
    )
    _validate_typed_stable_id(
        String(manifest.starting_spawn_id),
        "spawn.",
        &"project.manifest.starting_spawn",
        &"world.starting_spawn",
        "starting spawn",
        "spawn.entry",
        validation,
        source
    )


static func _validate_typed_stable_id(
    value: String,
    required_prefix: String,
    code: StringName,
    field_name: StringName,
    label: String,
    example: String,
    validation: ValidationResult,
    source: String
) -> void:
    if StableId.is_valid_text(value) and value.begins_with(required_prefix):
        return

    validation.add_error(
        code,
        "Project %s must be a valid stable ID in the '%s' namespace." % [label, required_prefix],
        source,
        field_name,
        "Use an ID such as '%s'." % example
    )


static func _read_required_integer(
    container: Dictionary,
    key: String,
    validation: ValidationResult,
    source: String,
    field_name: StringName
) -> Variant:
    if not container.has(key):
        _missing_field(key, validation, source, field_name)
        return null

    var value: Variant = container[key]
    if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
        validation.add_error(
            &"project.manifest.integer_type",
            "Field '%s' must be an integer." % String(field_name),
            source,
            field_name,
            "Provide a whole numeric value."
        )
        return null

    var numeric := float(value)
    if numeric != floorf(numeric):
        validation.add_error(
            &"project.manifest.integer_value",
            "Field '%s' must be a whole number." % String(field_name),
            source,
            field_name,
            "Remove the fractional component."
        )
        return null

    return int(numeric)


static func _read_required_string(
    container: Dictionary,
    key: String,
    validation: ValidationResult,
    source: String,
    field_name: StringName
) -> Variant:
    if not container.has(key):
        _missing_field(key, validation, source, field_name)
        return null

    var value: Variant = container[key]
    if typeof(value) != TYPE_STRING:
        validation.add_error(
            &"project.manifest.string_type",
            "Field '%s' must be a string." % String(field_name),
            source,
            field_name,
            "Provide a quoted text value."
        )
        return null

    return String(value)


static func _read_required_dictionary(
    container: Dictionary,
    key: String,
    validation: ValidationResult,
    source: String,
    field_name: StringName
) -> Variant:
    if not container.has(key):
        _missing_field(key, validation, source, field_name)
        return null

    var value: Variant = container[key]
    if typeof(value) != TYPE_DICTIONARY:
        validation.add_error(
            &"project.manifest.object_type",
            "Field '%s' must be an object/dictionary." % String(field_name),
            source,
            field_name,
            "Provide a JSON object for this section."
        )
        return null

    return value


static func _missing_field(
    key: String,
    validation: ValidationResult,
    source: String,
    field_name: StringName
) -> void:
    validation.add_error(
        &"project.manifest.missing_field",
        "Required project manifest field '%s' is missing." % key,
        source,
        field_name,
        "Add the required field to the project manifest."
    )


static func _warn_unknown_fields(
    container: Dictionary,
    known_fields: Array,
    validation: ValidationResult,
    source: String,
    prefix: String
) -> void:
    for raw_key in container.keys():
        var key := String(raw_key)
        if key in known_fields:
            continue
        validation.add_warning(
            &"project.manifest.unknown_field",
            "Unknown project manifest field '%s%s' was ignored." % [prefix, key],
            source,
            StringName(prefix + key),
            "Check for a typo or place intentionally custom metadata under 'extensions'."
        )
