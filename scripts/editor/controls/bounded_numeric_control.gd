@tool
class_name BoundedNumericControl
extends VBoxContainer

## Reusable numeric editor control backed by TunablePropertySpec.
##
## Visual grammar:
##   LOW BOUND ----- THUMB ----- HIGH BOUND - [CURRENT]
##
## The TunablePropertySpec remains authoritative for hard/recommended bounds,
## step size, units, descriptions, and warning text. The slider uses `step` as
## a convenience increment; the bracketed text field accepts any legal numeric
## value inside the hard range without quantizing it to slider steps.

signal value_changed(value: float)

# UI display precision only. Twelve decimal places preserve deliberately tiny
# legal bounds (for example 0.000001) while avoiding unreadable float noise.
# Expected useful presentation range: roughly 6–15 decimal places. Below that
# can hide intentionally tiny legal values; above that exposes float artifacts.
# Runtime values are never rounded to this precision.
const DISPLAY_DECIMAL_PRECISION := 12

# Minimum width of the bracketed free-entry field. 120 px keeps common signed
# and decimal values readable without dominating an inspector row.
# Expected useful UI range: roughly 80–240 px. Smaller widths truncate common
# values; larger widths consume horizontal space without improving semantics.
# This is presentation-only and must not become project/game tuning data.
const CURRENT_VALUE_MIN_WIDTH := 120.0

var spec: TunablePropertySpec
var current_value: float = 0.0

var _low_label: Label
var _slider: HSlider
var _high_label: Label
var _value_edit: LineEdit
var _unit_label: Label
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
    var changed := current_value != legal_value
    current_value = legal_value
    _sync_value_to_ui()
    if emit_change and changed:
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

    _value_edit = LineEdit.new()
    _value_edit.name = "CurrentValue"
    _value_edit.custom_minimum_size.x = CURRENT_VALUE_MIN_WIDTH
    _value_edit.text_submitted.connect(_on_value_text_submitted)
    _value_edit.focus_exited.connect(_on_value_focus_exited)
    row.add_child(_value_edit)

    _unit_label = Label.new()
    _unit_label.name = "Unit"
    row.add_child(_unit_label)

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
        _unit_label.text = ""
        _warning_label.visible = false
        _details_label.visible = false
        return

    if title != null:
        title.text = spec.display_name if not spec.display_name.is_empty() else String(spec.property_id)
        title.tooltip_text = spec.description

    if spec.range == null or not spec.range.is_definition_valid():
        _low_label.text = "INVALID"
        _high_label.text = "INVALID"
        _unit_label.text = ""
        _warning_label.text = "Invalid property range definition."
        _warning_label.visible = true
        return

    # Range property changes can emit value_changed while the control is being
    # configured. Suppress those setup-time signals so they cannot overwrite
    # the caller-provided current value before the first UI sync.
    _syncing = true
    _slider.min_value = spec.range.hard_min
    _slider.max_value = spec.range.hard_max
    _slider.step = spec.step
    _slider.allow_lesser = false
    _slider.allow_greater = false
    _syncing = false

    _low_label.text = _format_number(spec.range.hard_min)
    _high_label.text = _format_number(spec.range.hard_max)
    _unit_label.text = String(spec.unit)

    var detail_parts: Array[String] = []
    if not spec.description.strip_edges().is_empty():
        detail_parts.append(spec.description.strip_edges())
    if not spec.rationale.strip_edges().is_empty():
        detail_parts.append("Why: %s" % spec.rationale.strip_edges())
    _details_label.text = "\n".join(detail_parts)
    _details_label.visible = not detail_parts.is_empty()

    _refresh_warning()


func _sync_value_to_ui() -> void:
    if _slider == null or _value_edit == null:
        return

    _syncing = true
    _slider.set_value_no_signal(current_value)
    _value_edit.text = _format_number(current_value)
    _syncing = false
    _refresh_warning()


func _on_slider_value_changed(value: float) -> void:
    _accept_user_value(value)


func _on_value_text_submitted(text: String) -> void:
    _accept_user_text(text)


func _on_value_focus_exited() -> void:
    if _value_edit != null:
        _accept_user_text(_value_edit.text)


func _accept_user_text(text: String) -> void:
    if _syncing:
        return

    var trimmed := text.strip_edges()
    if not trimmed.is_valid_float():
        _value_edit.text = _format_number(current_value)
        _warning_label.text = "⚠ Enter a valid numeric value. The previous value was kept."
        _warning_label.visible = true
        return

    _accept_user_value(trimmed.to_float())


func _accept_user_value(value: float) -> void:
    if _syncing:
        return

    var legal_value := _coerce_to_legal(value)
    var changed := current_value != legal_value
    current_value = legal_value
    _sync_value_to_ui()
    if changed:
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
    if value == roundf(value):
        return str(int(roundf(value)))
    return String.num(value, DISPLAY_DECIMAL_PRECISION)
