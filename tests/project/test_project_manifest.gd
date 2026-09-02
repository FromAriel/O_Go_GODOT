extends SceneTree

var _failures := 0


func _initialize() -> void:
    _test_valid_manifest()
    _test_supported_tile_sizes()
    _test_invalid_tile_size()
    _test_schema_version()
    _test_stable_id_namespaces()
    _test_required_field_types()
    _test_unknown_fields_warn()
    _test_extensions_preserved()
    _test_json_failures()
    _test_file_loading()

    if _failures == 0:
        print("PASS: project manifest")
        quit(0)
        return

    push_error("FAIL: %d project manifest assertion(s) failed" % _failures)
    quit(1)


func _valid_manifest_data(tile_size: int = 32) -> Dictionary:
    return {
        "schema_version": ProjectManifest.CURRENT_SCHEMA_VERSION,
        "id": "project.demo",
        "title": "Demo Project",
        "version": "0.1.0",
        "world": {
            "tile_size": tile_size,
            "starting_map": "map.meadow",
            "starting_spawn": "spawn.entry",
        },
        "extensions": {},
    }


func _decode(data: Variant) -> ProjectLoadResult:
    return ProjectManifestLoader.load_text(JSON.stringify(data), "test://project.json")


func _test_valid_manifest() -> void:
    var result := _decode(_valid_manifest_data())
    _expect_true(result.is_success(), "valid manifest loads successfully")
    _expect_equal(result.manifest.schema_version, 1, "schema version decoded")
    _expect_equal(String(result.manifest.project_id), "project.demo", "project id decoded")
    _expect_equal(result.manifest.title, "Demo Project", "title decoded")
    _expect_equal(result.manifest.project_version, "0.1.0", "project version decoded")
    _expect_equal(result.manifest.tile_size, 32, "tile size decoded")
    _expect_equal(String(result.manifest.starting_map_id), "map.meadow", "starting map decoded")
    _expect_equal(String(result.manifest.starting_spawn_id), "spawn.entry", "starting spawn decoded")
    _expect_equal(result.validation.diagnostics.size(), 0, "valid manifest has no diagnostics")


func _test_supported_tile_sizes() -> void:
    for tile_size in ProjectManifest.SUPPORTED_TILE_SIZES:
        var result := _decode(_valid_manifest_data(tile_size))
        _expect_true(result.is_success(), "tile size %d is supported" % tile_size)
        _expect_equal(result.manifest.tile_size, tile_size, "tile size %d preserved" % tile_size)


func _test_invalid_tile_size() -> void:
    var result := _decode(_valid_manifest_data(24))
    _expect_true(not result.is_success(), "unsupported tile size rejected")
    _expect_true(_has_code(result, &"project.manifest.tile_size"), "tile-size diagnostic emitted")


func _test_schema_version() -> void:
    var data := _valid_manifest_data()
    data["schema_version"] = ProjectManifest.CURRENT_SCHEMA_VERSION + 1
    var result := _decode(data)
    _expect_true(not result.is_success(), "future unsupported schema rejected")
    _expect_true(_has_code(result, &"project.manifest.schema_version"), "schema diagnostic emitted")


func _test_stable_id_namespaces() -> void:
    var bad_project := _valid_manifest_data()
    bad_project["id"] = "game.demo"
    var project_result := _decode(bad_project)
    _expect_true(not project_result.is_success(), "project id requires project namespace")

    var bad_map := _valid_manifest_data()
    bad_map["world"]["starting_map"] = "npc.innkeeper"
    var map_result := _decode(bad_map)
    _expect_true(not map_result.is_success(), "starting map requires map namespace")
    _expect_true(_has_code(map_result, &"project.manifest.starting_map"), "map namespace diagnostic emitted")

    var bad_spawn := _valid_manifest_data()
    bad_spawn["world"]["starting_spawn"] = "map.entry"
    var spawn_result := _decode(bad_spawn)
    _expect_true(not spawn_result.is_success(), "starting spawn requires spawn namespace")
    _expect_true(_has_code(spawn_result, &"project.manifest.starting_spawn"), "spawn namespace diagnostic emitted")


func _test_required_field_types() -> void:
    var missing := _valid_manifest_data()
    missing["world"].erase("starting_spawn")
    var missing_result := _decode(missing)
    _expect_true(not missing_result.is_success(), "missing required field rejected")
    _expect_true(_has_code(missing_result, &"project.manifest.missing_field"), "missing-field diagnostic emitted")

    var fractional := _valid_manifest_data()
    fractional["world"]["tile_size"] = 32.5
    var fractional_result := _decode(fractional)
    _expect_true(not fractional_result.is_success(), "fractional tile size rejected")
    _expect_true(_has_code(fractional_result, &"project.manifest.integer_value"), "whole-number diagnostic emitted")

    var wrong_type := _valid_manifest_data()
    wrong_type["title"] = 123
    var type_result := _decode(wrong_type)
    _expect_true(not type_result.is_success(), "non-string title rejected")
    _expect_true(_has_code(type_result, &"project.manifest.string_type"), "string-type diagnostic emitted")


func _test_unknown_fields_warn() -> void:
    var data := _valid_manifest_data()
    data["mystery"] = true
    data["world"]["future_world_field"] = 7
    var result := _decode(data)

    _expect_true(result.is_success(), "unknown fields warn without invalidating manifest")
    _expect_equal(
        result.validation.count_by_severity(Diagnostic.Severity.WARNING),
        2,
        "unknown root/world fields each produce warning"
    )
    _expect_true(_has_code(result, &"project.manifest.unknown_field"), "unknown-field diagnostic emitted")


func _test_extensions_preserved() -> void:
    var data := _valid_manifest_data()
    data["extensions"] = {
        "example.plugin": {
            "enabled": true,
            "weight": 0.75,
        },
    }
    var result := _decode(data)

    _expect_true(result.is_success(), "extension metadata accepted")
    _expect_true(result.manifest.extensions.has("example.plugin"), "extension namespace preserved")
    _expect_equal(
        result.manifest.extensions["example.plugin"]["weight"],
        0.75,
        "nested extension data preserved"
    )


func _test_json_failures() -> void:
    var malformed := ProjectManifestLoader.load_text("{ nope", "test://malformed.json")
    _expect_true(not malformed.is_success(), "malformed JSON rejected")
    _expect_true(_has_code(malformed, &"project.manifest.json"), "JSON diagnostic emitted")

    var wrong_root := ProjectManifestLoader.load_text("[]", "test://array.json")
    _expect_true(not wrong_root.is_success(), "non-object JSON root rejected")
    _expect_true(_has_code(wrong_root, &"project.manifest.root_type"), "root-type diagnostic emitted")


func _test_file_loading() -> void:
    var path := "user://o_go_project_manifest_test.json"
    var file := FileAccess.open(path, FileAccess.WRITE)
    _expect_true(file != null, "temporary manifest file opens for writing")
    if file == null:
        return

    file.store_string(JSON.stringify(_valid_manifest_data(64)))
    file.close()

    var loaded := ProjectManifestLoader.load_file(path)
    _expect_true(loaded.is_success(), "manifest loads from file")
    _expect_equal(loaded.manifest.tile_size, 64, "file-loaded tile size preserved")
    _expect_equal(loaded.source_path, path, "file source path preserved")

    var absolute_path := ProjectSettings.globalize_path(path)
    DirAccess.remove_absolute(absolute_path)

    var missing := ProjectManifestLoader.load_file(path)
    _expect_true(not missing.is_success(), "missing manifest file rejected")
    _expect_true(_has_code(missing, &"project.manifest.file_missing"), "missing-file diagnostic emitted")


func _has_code(result: ProjectLoadResult, code: StringName) -> bool:
    for diagnostic in result.validation.diagnostics:
        if diagnostic.code == code:
            return true
    return false


func _expect_true(condition: bool, label: String) -> void:
    if not condition:
        _record_failure(label)


func _expect_equal(actual, expected, label: String) -> void:
    if actual != expected:
        _record_failure("%s (expected %s, got %s)" % [label, expected, actual])


func _record_failure(message: String) -> void:
    _failures += 1
    push_error(message)
