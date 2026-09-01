extends SceneTree

var _failures := 0
var _control: BoundedNumericControl


func _initialize() -> void:
    var spec := _make_run_speed_spec()
    _control = BoundedNumericControl.new()
    _control.configure(spec, 300.0)
    root.add_child(_control)
    call_deferred("_run_tests")


func _run_tests() -> void:
    _test_layout(_control)
    _test_recommended_and_warning_states(_control)
    _test_manual_unquantized_entry(_control)
    _test_hard_bound_clamping(_control)
    _test_invalid_text_preserves_value(_control)

    _control.queue_free()

    if _failures == 0:
        print("PASS: bounded numeric control")
        quit(0)
        return

    push_error("FAIL: %d bounded numeric control assertion(s) failed" % _failures)
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


func _test_layout(control: BoundedNumericControl) -> void:
    var row := control.get_node("ValueRow") as HBoxContainer
    var slider := control.get_node("ValueRow/Slider") as HSlider
    var current := control.get_node("ValueRow/CurrentValue") as LineEdit

    _expect_true(row != null, "value row exists")
    _expect_equal((control.get_node("Title") as Label).text, "Run Speed", "title uses metadata")
    _expect_equal((control.get_node("ValueRow/LowBound") as Label).text, "0.000001", "low hard bound visible")
    _expect_equal((control.get_node("ValueRow/HighBound") as Label).text, "12000", "high hard bound visible")
    _expect_equal((control.get_node("ValueRow/OpenBracket") as Label).text, "[", "current value opens with bracket")
    _expect_equal((control.get_node("ValueRow/CloseBracket") as Label).text, "]", "current value closes with bracket")
    _expect_equal((control.get_node("ValueRow/Unit") as Label).text, "pixels_per_second", "unit rendered from metadata")
    _expect_equal(current.text, "300", "current value rendered")
    _expect_equal(slider.min_value, 0.000001, "slider hard minimum comes from spec")
    _expect_equal(slider.max_value, 12000.0, "slider hard maximum comes from spec")
    _expect_equal(slider.step, 1.0, "slider step comes from spec")


func _test_recommended_and_warning_states(control: BoundedNumericControl) -> void:
    control.set_current_value(300.0)
    _expect_equal(control.get_warning_text(), "", "recommended value has no warning")

    control.set_current_value(8000.0)
    var warning := control.get_warning_text()
    _expect_true(not warning.is_empty(), "legal adventurous value shows warning")
    _expect_true(warning.contains("outside the recommended range"), "warning explains recommendation")
    _expect_true(warning.contains("teleport"), "warning includes consequence metadata")
    _expect_equal(control.get_current_value(), 8000.0, "warning does not reject legal value")


func _test_manual_unquantized_entry(control: BoundedNumericControl) -> void:
    var current := control.get_node("ValueRow/CurrentValue") as LineEdit
    current.text = "333.333"
    current.text_submitted.emit(current.text)

    _expect_true(is_equal_approx(control.get_current_value(), 333.333), "manual value is not quantized to slider step")
    _expect_equal(current.text, "333.333", "manual precision remains visible")


func _test_hard_bound_clamping(control: BoundedNumericControl) -> void:
    var current := control.get_node("ValueRow/CurrentValue") as LineEdit
    current.text = "99999"
    current.text_submitted.emit(current.text)

    _expect_equal(control.get_current_value(), 12000.0, "manual value above hard maximum clamps")
    _expect_equal(current.text, "12000", "clamped hard maximum is reflected in current field")

    current.text = "0"
    current.text_submitted.emit(current.text)
    _expect_true(is_equal_approx(control.get_current_value(), 0.000001), "manual value below hard minimum clamps")


func _test_invalid_text_preserves_value(control: BoundedNumericControl) -> void:
    control.set_current_value(300.0)
    var current := control.get_node("ValueRow/CurrentValue") as LineEdit
    current.text = "warp-speed"
    current.text_submitted.emit(current.text)

    _expect_equal(control.get_current_value(), 300.0, "invalid text preserves prior value")
    _expect_equal(current.text, "300", "invalid text restores prior display")
    _expect_true(control.get_warning_text().contains("valid numeric value"), "invalid text gives user-facing warning")


func _expect_true(condition: bool, label: String) -> void:
    if not condition:
        _record_failure(label)


func _expect_equal(actual, expected, label: String) -> void:
    if actual != expected:
        _record_failure("%s (expected %s, got %s)" % [label, expected, actual])


func _record_failure(message: String) -> void:
    _failures += 1
    push_error(message)
