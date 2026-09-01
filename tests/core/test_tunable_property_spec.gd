extends SceneTree

var _failures := 0


func _initialize() -> void:
    _test_valid_definition()
    _test_definition_failures()
    _test_recommended_vs_hard_bounds()
    _test_step_is_editor_metadata()
    _test_extreme_legal_values()

    if _failures == 0:
        print("PASS: tunable property metadata")
        quit(0)
        return

    push_error("FAIL: %d tunable property assertion(s) failed" % _failures)
    quit(1)


func _make_run_speed_spec() -> TunablePropertySpec:
    var spec := TunablePropertySpec.new()
    spec.property_id = &"movement.run_speed"
    spec.display_name = "Run Speed"
    spec.description = "Player movement velocity while running."
    spec.default_value = 300.0
    spec.step = 1.0
    spec.unit = &"pixels_per_second"
    spec.rationale = "Values around 250–450 produce conventional JRPG movement."
    spec.consequences = "Extremely high values can appear to teleport and may expose collision limitations."
    spec.range.hard_min = 0.000001
    spec.range.hard_max = 12000.0
    spec.range.recommended_min = 80.0
    spec.range.recommended_max = 700.0
    return spec


func _test_valid_definition() -> void:
    var spec := _make_run_speed_spec()
    var result := spec.validate_definition()

    _expect_true(result.is_valid(), "complete property definition is valid")
    _expect_equal(result.diagnostics.size(), 0, "complete property definition has no diagnostics")
    _expect_equal(String(spec.unit), "pixels_per_second", "unit metadata preserved")
    _expect_equal(spec.step, 1.0, "step metadata preserved")
    _expect_true(not spec.rationale.is_empty(), "rationale metadata preserved")
    _expect_true(not spec.consequences.is_empty(), "consequence metadata preserved")


func _test_definition_failures() -> void:
    var invalid_id := _make_run_speed_spec()
    invalid_id.property_id = &"RunSpeed"
    _expect_true(invalid_id.validate_definition().has_errors(), "invalid stable property ID rejected")

    var invalid_range := _make_run_speed_spec()
    invalid_range.range.recommended_min = 900.0
    invalid_range.range.recommended_max = 700.0
    _expect_true(invalid_range.validate_definition().has_errors(), "misordered range rejected")

    var invalid_default := _make_run_speed_spec()
    invalid_default.default_value = 12001.0
    _expect_true(invalid_default.validate_definition().has_errors(), "default outside hard range rejected")

    var negative_step := _make_run_speed_spec()
    negative_step.step = -1.0
    _expect_true(negative_step.validate_definition().has_errors(), "negative step rejected")

    var sparse_docs := _make_run_speed_spec()
    sparse_docs.description = ""
    sparse_docs.rationale = ""
    var sparse_result := sparse_docs.validate_definition()
    _expect_true(sparse_result.is_valid(), "missing explanatory metadata warns without invalidating definition")
    _expect_equal(
        sparse_result.count_by_severity(Diagnostic.Severity.WARNING),
        2,
        "missing description and rationale produce warnings"
    )


func _test_recommended_vs_hard_bounds() -> void:
    var spec := _make_run_speed_spec()

    var ordinary := spec.validate_value(300.0)
    _expect_true(ordinary.is_valid(), "recommended value valid")
    _expect_equal(ordinary.diagnostics.size(), 0, "recommended value produces no warning")

    var adventurous := spec.validate_value(8000.0)
    _expect_true(adventurous.is_valid(), "legal value outside recommendation remains valid")
    _expect_equal(
        adventurous.count_by_severity(Diagnostic.Severity.WARNING),
        1,
        "legal adventurous value produces one warning"
    )

    var too_fast := spec.validate_value(12001.0)
    _expect_true(too_fast.has_errors(), "value beyond hard maximum rejected")

    var too_slow := spec.validate_value(0.0)
    _expect_true(too_slow.has_errors(), "value below hard minimum rejected")

    _expect_equal(spec.clamp_to_legal_range(99999.0), 12000.0, "explicit clamp helper uses hard maximum")


func _test_step_is_editor_metadata() -> void:
    var spec := _make_run_speed_spec()
    spec.step = 100.0

    var arbitrary := spec.validate_value(333.333)
    _expect_true(arbitrary.is_valid(), "manual value need not align to editor step")
    _expect_equal(arbitrary.diagnostics.size(), 0, "step mismatch is not a validation warning")

    spec.step = 0.0
    _expect_true(spec.validate_definition().is_valid(), "zero step permits continuous editor input")


func _test_extreme_legal_values() -> void:
    var spec := _make_run_speed_spec()

    var exact_min := spec.validate_value(0.000001)
    _expect_true(exact_min.is_valid(), "hard minimum itself is legal")
    _expect_equal(
        exact_min.count_by_severity(Diagnostic.Severity.WARNING),
        1,
        "hard minimum outside recommendation warns only"
    )

    var exact_max := spec.validate_value(12000.0)
    _expect_true(exact_max.is_valid(), "hard maximum itself is legal")
    _expect_equal(
        exact_max.count_by_severity(Diagnostic.Severity.WARNING),
        1,
        "hard maximum outside recommendation warns only"
    )

    var odd_but_legal := spec.validate_value(8000.123456)
    _expect_true(odd_but_legal.is_valid(), "high precision legal value accepted")


func _expect_true(condition: bool, label: String) -> void:
    if not condition:
        _record_failure(label)


func _expect_equal(actual, expected, label: String) -> void:
    if actual != expected:
        _record_failure("%s (expected %s, got %s)" % [label, expected, actual])


func _record_failure(message: String) -> void:
    _failures += 1
    push_error(message)
