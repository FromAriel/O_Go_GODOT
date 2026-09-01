extends SceneTree

const StableIdType = preload("res://scripts/core/ids/stable_id.gd")
const RangeSpecType = preload("res://scripts/core/values/range_spec.gd")
const SpatialConventionsType = preload("res://scripts/core/spatial/spatial_conventions.gd")
const Direction8Type = preload("res://scripts/core/spatial/direction8.gd")
const AssetReferenceType = preload("res://scripts/core/content/asset_reference.gd")
const DiagnosticType = preload("res://scripts/core/validation/diagnostic.gd")
const ValidationResultType = preload("res://scripts/core/validation/validation_result.gd")

var _failures := 0


func _initialize() -> void:
    _test_stable_ids()
    _test_range_spec()
    _test_spatial_conventions()
    _test_direction8()
    _test_asset_reference()
    _test_validation_result()

    if _failures == 0:
        print("PASS: shared primitive tests")
    else:
        push_error("FAIL: %d shared primitive assertion(s) failed" % _failures)

    quit(_failures)


func _test_stable_ids() -> void:
    _expect_true(StableIdType.is_valid_text("map.village"), "basic stable ID")
    _expect_true(
        StableIdType.is_valid_text("npc.village.blacksmith"),
        "multi-segment stable ID"
    )
    _expect_false(StableIdType.is_valid_text("Map.village"), "uppercase ID rejected")
    _expect_false(StableIdType.is_valid_text("map..village"), "empty segment rejected")
    _expect_false(StableIdType.is_valid_text("map.village-inn"), "hyphen rejected")
    _expect_false(StableIdType.is_valid_text("village"), "unnamespaced ID rejected")


func _test_range_spec() -> void:
    var spec = RangeSpecType.new()
    spec.hard_min = 0.0
    spec.hard_max = 10.0
    spec.recommended_min = 2.0
    spec.recommended_max = 8.0

    _expect_true(spec.is_definition_valid(), "range definition valid")
    _expect_true(spec.contains(10.0), "hard maximum is legal")
    _expect_false(spec.contains(10.1), "above hard maximum rejected")
    _expect_true(spec.is_recommended(5.0), "recommended value recognized")
    _expect_equal(spec.clamp_to_hard_bounds(99.0), 10.0, "hard clamp")
    _expect_equal(
        spec.status_for(9.0),
        RangeSpecType.ValueStatus.ABOVE_RECOMMENDED,
        "legal but non-recommended status"
    )


func _test_spatial_conventions() -> void:
    var cell_size := Vector2i(32, 32)
    _expect_equal(
        SpatialConventionsType.grid_to_world_origin(Vector2i(2, 3), cell_size),
        Vector2(64.0, 96.0),
        "grid to world conversion"
    )
    _expect_equal(
        SpatialConventionsType.world_to_grid_floor(Vector2(95.9, 64.0), cell_size),
        Vector2i(2, 2),
        "world to grid uses floor"
    )


func _test_direction8() -> void:
    _expect_equal(
        Direction8Type.from_vector(Vector2(4.0, -2.0)),
        Direction8Type.Value.NORTH_EAST,
        "vector resolves to northeast"
    )
    _expect_equal(
        Direction8Type.from_vector(Vector2.ZERO),
        Direction8Type.Value.NONE,
        "zero vector resolves to none"
    )
    _expect_true(
        is_equal_approx(Direction8Type.to_vector(Direction8Type.Value.SOUTH_WEST).length(), 1.0),
        "diagonal direction vector is normalized"
    )


func _test_asset_reference() -> void:
    var reference = AssetReferenceType.new()
    reference.content_id = "prop.tree.oak"
    reference.expected_kind = &"prop"
    reference.path_hint = "res://assets/props/oak.png"
    _expect_true(reference.is_valid(), "stable content reference valid")

    reference.content_id = "Bad Reference"
    _expect_false(reference.is_valid(), "invalid stable content reference rejected")


func _test_validation_result() -> void:
    var result = ValidationResultType.new()
    result.add_warning(&"test.warning", "Warning only")
    _expect_true(result.is_valid(), "warning does not invalidate result")
    _expect_equal(
        result.count_by_severity(DiagnosticType.Severity.WARNING),
        1,
        "warning counted"
    )

    var other = ValidationResultType.new()
    other.add_error(&"test.error", "Error")
    result.merge(other)
    _expect_false(result.is_valid(), "error invalidates merged result")
    _expect_equal(
        result.count_by_severity(DiagnosticType.Severity.ERROR),
        1,
        "error counted"
    )


func _expect_true(condition: bool, label: String) -> void:
    if not condition:
        _record_failure(label)


func _expect_false(condition: bool, label: String) -> void:
    if condition:
        _record_failure(label)


func _expect_equal(actual, expected, label: String) -> void:
    if actual != expected:
        _record_failure("%s — expected %s, got %s" % [label, expected, actual])


func _record_failure(message: String) -> void:
    _failures += 1
    push_error(message)
