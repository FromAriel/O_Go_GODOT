extends SceneTree

## Repository-level P4 integration test.
##
## This proves the checked-in demo manifest loads through the same loader used by
## code/editor paths and that spatial conversion consumes the project-selected
## tile scale rather than assuming a hidden 32px cell size.

const DEMO_MANIFEST_PATH := "res://projects/demo/project.json"
const SAMPLE_GRID_POSITION := Vector2i(2, 3)

var _failures := 0


func _initialize() -> void:
    _test_repository_demo_manifest()
    _test_supported_tile_scales_drive_spatial_conversion()

    if _failures == 0:
        print("PASS: project bootstrap")
        quit(0)
        return

    push_error("FAIL: %d project bootstrap assertion(s) failed" % _failures)
    quit(1)


func _test_repository_demo_manifest() -> void:
    var result := ProjectManifestLoader.load_file(DEMO_MANIFEST_PATH)
    _expect_true(result.is_success(), "repository demo manifest loads successfully")
    if not result.is_success():
        return

    _expect_equal(result.source_path, DEMO_MANIFEST_PATH, "demo source path preserved")
    _expect_equal(String(result.manifest.project_id), "project.demo", "demo project id")
    _expect_equal(result.manifest.title, "O Go GODOT Demo", "demo title")
    _expect_equal(result.manifest.tile_size, 32, "demo tile size")
    _expect_equal(String(result.manifest.starting_map_id), "map.meadow", "demo starting map")
    _expect_equal(
        String(result.manifest.starting_spawn_id),
        "spawn.meadow.entry",
        "demo starting spawn"
    )


func _test_supported_tile_scales_drive_spatial_conversion() -> void:
    for tile_size in ProjectManifest.SUPPORTED_TILE_SIZES:
        var cell_size := Vector2i(tile_size, tile_size)
        var actual := SpatialConventions.grid_to_world_origin(SAMPLE_GRID_POSITION, cell_size)
        var expected := Vector2(
            SAMPLE_GRID_POSITION.x * tile_size,
            SAMPLE_GRID_POSITION.y * tile_size
        )
        _expect_equal(
            actual,
            expected,
            "spatial conversion derives from %dpx project tile size" % tile_size
        )


func _expect_true(condition: bool, label: String) -> void:
    if not condition:
        _record_failure(label)


func _expect_equal(actual, expected, label: String) -> void:
    if actual != expected:
        _record_failure("%s (expected %s, got %s)" % [label, expected, actual])


func _record_failure(message: String) -> void:
    _failures += 1
    push_error(message)
