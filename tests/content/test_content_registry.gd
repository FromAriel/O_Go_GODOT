extends SceneTree

var _failures := 0


func _initialize() -> void:
    _test_registration_and_resolution()
    _test_duplicate_preserves_original()
    _test_missing_and_invalid_references()
    _test_kind_validation()
    _test_asset_reference_resolution()
    _test_project_references_and_search_listing()

    if _failures == 0:
        print("PASS: content registry")
        quit(0)
        return

    push_error("FAIL: %d content registry assertion(s) failed" % _failures)
    quit(1)


func _definition(id: String, kind: String, path: String = "") -> ContentDefinition:
    return ContentDefinition.new(StringName(id), StringName(kind), path)


func _test_registration_and_resolution() -> void:
    var registry := ContentRegistry.new()
    var meadow := _definition("map.meadow", "map", "projects/demo/maps/meadow.json")
    var registration := registry.register_definition(meadow, "test")

    _expect_true(registration.is_valid(), "valid definition registers")
    _expect_equal(registry.size(), 1, "registry size increments")
    _expect_true(registry.contains_id(&"map.meadow"), "registered ID is present")

    var lookup := registry.resolve_id(&"map.meadow", &"map", "test")
    _expect_true(lookup.is_success(), "registered ID resolves")
    _expect_true(lookup.definition == meadow, "lookup returns registered descriptor")
    _expect_equal(
        lookup.definition.source_path,
        "projects/demo/maps/meadow.json",
        "source path preserved without loading it"
    )


func _test_duplicate_preserves_original() -> void:
    var registry := ContentRegistry.new()
    var original := _definition("map.meadow", "map", "first.json")
    var duplicate := _definition("map.meadow", "map", "second.json")

    _expect_true(registry.register_definition(original).is_valid(), "original registers")
    var duplicate_result := registry.register_definition(duplicate)
    _expect_true(not duplicate_result.is_valid(), "duplicate registration fails")
    _expect_true(
        _has_code(duplicate_result, &"content.registry.duplicate_id"),
        "duplicate diagnostic emitted"
    )
    _expect_equal(registry.size(), 1, "duplicate does not grow registry")
    _expect_equal(
        registry.resolve_id(&"map.meadow").definition.source_path,
        "first.json",
        "duplicate does not replace original"
    )


func _test_missing_and_invalid_references() -> void:
    var registry := ContentRegistry.new()

    var missing := registry.resolve_id(&"map.missing", &"map", "test")
    _expect_true(not missing.is_success(), "missing ID fails lookup")
    _expect_true(
        _has_code(missing.validation, &"content.registry.missing_reference"),
        "missing-reference diagnostic emitted"
    )

    var invalid := registry.resolve_id(StringName("not valid"), &"map", "test")
    _expect_true(not invalid.is_success(), "invalid stable ID fails lookup")
    _expect_true(
        _has_code(invalid.validation, &"content.registry.invalid_reference"),
        "invalid-reference diagnostic emitted"
    )

    var null_reference := registry.resolve_reference(null, "test")
    _expect_true(not null_reference.is_success(), "null AssetReference fails")


func _test_kind_validation() -> void:
    var registry := ContentRegistry.new()

    var bad_kind := registry.register_definition(_definition("map.meadow", "Map"), "test")
    _expect_true(not bad_kind.is_valid(), "uppercase kind rejected")
    _expect_true(
        _has_code(bad_kind, &"content.registry.invalid_kind"),
        "invalid-kind diagnostic emitted"
    )

    var namespace_mismatch := registry.register_definition(
        _definition("npc.blacksmith", "actor"),
        "test"
    )
    _expect_true(not namespace_mismatch.is_valid(), "kind/namespace mismatch rejected")
    _expect_true(
        _has_code(namespace_mismatch, &"content.registry.kind_namespace"),
        "kind-namespace diagnostic emitted"
    )

    _expect_true(
        registry.register_definition(_definition("map.meadow", "map")).is_valid(),
        "map registers for lookup kind test"
    )
    var wrong_expected_kind := registry.resolve_id(&"map.meadow", &"actor", "test")
    _expect_true(not wrong_expected_kind.is_success(), "wrong expected kind fails lookup")
    _expect_true(wrong_expected_kind.definition != null, "found descriptor remains inspectable")
    _expect_true(
        _has_code(wrong_expected_kind.validation, &"content.registry.kind_mismatch"),
        "kind-mismatch diagnostic emitted"
    )

    var invalid_expected_kind := registry.resolve_id(&"map.meadow", &"Bad Kind", "test")
    _expect_true(not invalid_expected_kind.is_success(), "invalid expected kind rejected")
    _expect_true(
        _has_code(invalid_expected_kind.validation, &"content.registry.invalid_expected_kind"),
        "invalid-expected-kind diagnostic emitted"
    )


func _test_asset_reference_resolution() -> void:
    var registry := ContentRegistry.new()
    var portrait := _definition("asset.hero_portrait", "asset", "assets/hero.png")
    _expect_true(registry.register_definition(portrait).is_valid(), "asset definition registers")

    var reference := AssetReference.new()
    reference.content_id = "asset.hero_portrait"
    reference.expected_kind = &"asset"
    reference.path_hint = "old/location/hero.png"

    var lookup := registry.resolve_reference(reference, "test")
    _expect_true(lookup.is_success(), "AssetReference resolves through stable ID")
    _expect_true(lookup.definition == portrait, "path hint is not authoritative identity")


func _test_project_references_and_search_listing() -> void:
    var registry := ContentRegistry.new()
    var definitions := [
        _definition("map.meadow", "map", "projects/demo/maps/meadow.json"),
        _definition("spawn.meadow.entry", "spawn", "projects/demo/maps/meadow.json"),
        _definition("prop.tree.oak", "prop", "projects/demo/props/tree_oak.json"),
        _definition("actor.player", "actor", "projects/demo/actors/player.json"),
        _definition("dialogue.blacksmith.intro", "dialogue", "projects/demo/dialogue/blacksmith.json"),
        _definition("asset.tiles.grass", "asset", "projects/demo/assets/grass.png"),
    ]
    var registration := registry.register_all(definitions, "test")
    _expect_true(registration.is_valid(), "representative content kinds register together")
    _expect_equal(registry.size(), 6, "all representative definitions registered")

    var project := ProjectManifestLoader.load_file("res://projects/demo/project.json")
    _expect_true(project.is_success(), "repository demo project loads for registry integration")
    if project.is_success():
        _expect_true(
            registry.resolve_id(project.manifest.starting_map_id, &"map", "project").is_success(),
            "project starting map resolves by stable ID"
        )
        _expect_true(
            registry.resolve_id(project.manifest.starting_spawn_id, &"spawn", "project").is_success(),
            "project starting spawn resolves by stable ID"
        )

    var listed := registry.all_definitions()
    _expect_equal(listed.size(), 6, "search listing exposes all descriptors")
    _expect_equal(listed[0].id_text(), "actor.player", "search listing is stable/sorted")
    _expect_equal(listed[5].id_text(), "spawn.meadow.entry", "search listing sort is deterministic")


func _has_code(validation: ValidationResult, code: StringName) -> bool:
    for diagnostic in validation.diagnostics:
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
