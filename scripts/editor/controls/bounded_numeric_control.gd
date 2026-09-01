@tool
class_name BoundedNumericControl
extends VBoxContainer

## Reusable numeric editor control backed by TunablePropertySpec.
##
## Visual grammar:
##   LOW BOUND ----- THUMB ----- HIGH BOUND - [CURRENT]
##
## The TunablePropertySpec remains authoritative for hard/recommended bounds,
## step size, units, descriptions, and warning text. This control only presents
## and edits a current value. Values outside the recommended range remain legal;
## values outside the hard range are clamped before they are emitted.

signal value_changed(value: float)

var spec: TunablePropertySpec
var current_value: float = 0.0

var _low_label: Label
var _slider: HSlider
var _high_label: Label
var _value_box: SpinBox
var _warning_label: Label
var _details_label: Label
var _syncing: bool = false


func _ready() -> void:
    _ensure_ui()
    _apply_spec_to_ui()
    _sync_value_to_ui()


func configure(property_spec: TunablePropertySpec, value: float) -> void:
    spec = property_spec
    current_value = _coerce_to_legal(value)
    if is_node_ready():
        _ensure_ui()
        _apply_spec_to_ui()
        _sync_value_to_ui()


func set_current_value(value: float, emit_change: bool = false) -> void:
    var legal_value := _coerce_to_legal(value)
    if is_equal_approx(current_value, legal_value):
        _sync_value_to_ui()
        return

    current_value = legal_value
    _sync_value_to_ui()
    if emit_change:
        value_changed.emit(current_value)


func get_current_value() -> float:
    return current_value


func get_warning_text() -> String:
    if _warning_label == null:
        return ""
    return _warning_label.text


func _ensure_ui() -> void:
    if _slider != null:
        return

    var title := Label.new()
    title.name = "Title"
    title.text = "Value"
    add_child(title)

    var row := HBoxContainer.new()
    row.name = "ValueRow"
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(row)

    _low_label = Label.new()
    _low_label.name = "LowBound"
    row.add_child(_low_label)

    _slider = HSlider.new()
    _slider.name = "Slider"
    _slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _slider.value_changed.connect(_on_slider_value_changed)
    row.add_child(_slider)

    _high_label = Label.new()
    _high_label.name = "HighBound"
    row.add_child(_high_label)

    var separator := Label.new()
    separator.name = "Separator"
    separator.text = "-"
    row.add_child(separator)

    var open_bracket := Label.new()
    open_bracket.name = "OpenBracket"
    open_bracket.text = "["
    row.add_child(open_bracket)

    _value_box = SpinBox.new()
    _value_box.name = "CurrentValue"
    _value_box.custom_minimum_size.x = 120.0
    _value_box.value_changed.connect(_on_value_box_value_changed)
    row.add_child(_value_box)

    var close_bracket := Label.new()
    close_bracket.name = "CloseBracket"
    close_bracket.text = "]"
    row.add_child(close_bracket)

    _warning_label = Label.new()
    _warning_label.name = "Warning"
    _warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _warning_label.visible = false
    add_child(_warning_label)

    _details_label = Label.new()
    _details_label.name = "Details"
    _details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _details_label.visible = false
    add_child(_details_label)


func _apply_spec_to_ui() -> void:
    if _slider == null:
        return

    var title := get_node_or_null("Title") as Label
    if spec == null:
        if title != null:
            title.text = "Value"
        _low_label.text = "—"
        _high_label.text = "—"
        _value_box.suffix = ""
        _warning_label.visible = false
        _details_label.visible = false
        return

    if title != null:
        title.text = spec.display_name if not spec.display_name.is_empty() else String(spec.property_id)
        title.tooltip_text = spec.description

    if spec.range == null or not spec.range.is_definition_valid():
        _low_label.text = "INVALID"
        _high_label.text = "INVALID"
        _warning_label.text = "Invalid property range definition."
        _warning_label.visible = true
        return

    _slider.min_value = spec.range.hard_min
    _slider.max_value = spec.range.hard_max
    _slider.step = spec.step
    _slider.allow_lesser = false
    _slider.allow_greater = false

    _value_box.min_value = spec.range.hard_min
    _value_box.max_value = spec.range.hard_max
    _value_box.step = spec.step
    _value_box.allow_lesser = false
    _value_box.allow_greater = false
    _value_box.suffix = " %s" % String(spec.unit) if not String(spec.unit).is_empty() else ""

    _low_label.text = _format_number(spec.range.hard_min)
    _high_label.text = _format_number(spec.range.hard_max)

    var detail_parts: Array[String] = []
    if not spec.description.strip_edges().is_empty():
        detail_parts.append(spec.description.strip_edges())
    if not spec.rationale.strip_edges().is_empty():
        detail_parts.append("Why: %s" % spec.rationale.strip_edges())
    _details_label.text = "\n".join(detail_parts)
    _details_label.visible = not detail_parts.is_empty()

    _refresh_warning()


func _sync_value_to_ui() -> void:
    if _slider == null or _value_box == null:
        return

    _syncing = true
    _slider.set_value_no_signal(current_value)
    _value_box.set_value_no_signal(current_value)
    _syncing = false
    _refresh_warning()


func _on_slider_value_changed(value: float) -> void:
    _accept_user_value(value)


func _on_value_box_value_changed(value: float) -> void:
    _accept_user_value(value)


func _accept_user_value(value: float) -> void:
    if _syncing:
        return

    current_value = _coerce_to_legal(value)
    _sync_value_to_ui()
    value_changed.emit(current_value)


func _coerce_to_legal(value: float) -> float:
    if spec == null:
        return value
    return spec.clamp_to_legal_range(value)


func _refresh_warning() -> void:
    if _warning_label == null:
        return

    _warning_label.text = ""
    _warning_label.visible = false
    if spec == null or spec.range == null or not spec.range.is_definition_valid():
        return

    var validation := spec.validate_value(current_value, "BoundedNumericControl")
    for diagnostic in validation.diagnostics:
        if diagnostic.is_warning():
            _warning_label.text = "⚠ %s" % diagnostic.message
            if not diagnostic.suggested_fix.is_empty():
                _warning_label.text += " %s" % diagnostic.suggested_fix
            _warning_label.visible = true
            return


func _format_number(value: float) -> String:
    if is_equal_approx(value, roundf(value)):
        return str(int(roundf(value)))
    return str(value)
