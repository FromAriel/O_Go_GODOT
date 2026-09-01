class_name TunablePropertySpec
extends Resource

## Authoritative metadata for one designer/user-tunable numeric property.
##
## Runtime validation and future editor controls read the same definition so
## bounds, defaults, units, rationale, and warnings never drift between code
## and UI. `step` describes a convenient editor increment only; it does not
## restrict manually entered values inside the hard range.

@export var property_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var default_value: float = 0.0
@export var range: RangeSpec = RangeSpec.new()
@export var step: float = 0.0
@export var unit: StringName = &""
@export_multiline var rationale: String = ""
@export_multiline var consequences: String = ""


func validate_definition(source: String = "") -> ValidationResult:
    var result := ValidationResult.new()
    var diagnostic_source := _diagnostic_source(source)

    if not StableId.is_valid_text(String(property_id)):
        result.add_error(
            &"property.definition.invalid_id",
            "Property ID must be a valid lowercase namespaced stable ID.",
            diagnostic_source,
            &"property_id",
            "Use an ID such as `movement.run_speed`."
        )

    if display_name.strip_edges().is_empty():
        result.add_error(
            &"property.definition.missing_display_name",
            "Tunable properties require a human-readable display name.",
            diagnostic_source,
            &"display_name"
        )

    if description.strip_edges().is_empty():
        result.add_warning(
            &"property.definition.missing_description",
            "A description should explain what the property controls.",
            diagnostic_source,
            &"description"
        )

    if range == null:
        result.add_error(
            &"property.definition.missing_range",
            "Tunable properties require a RangeSpec.",
            diagnostic_source,
            &"range"
        )
        return result

    if not range.is_definition_valid():
        result.add_error(
            &"property.definition.invalid_range",
            "Hard and recommended bounds must be ordered: hard_min <= recommended_min <= recommended_max <= hard_max.",
            diagnostic_source,
            &"range"
        )
        return result

    if not range.contains(default_value):
        result.add_error(
            &"property.definition.default_out_of_bounds",
            "Default value %s lies outside the legal hard range [%s, %s]." % [default_value, range.hard_min, range.hard_max],
            diagnostic_source,
            &"default_value",
            "Choose a default inside the hard range."
        )
    elif not range.is_recommended(default_value):
        result.add_warning(
            &"property.definition.default_outside_recommended",
            "Default value %s is legal but outside the recommended range [%s, %s]." % [default_value, range.recommended_min, range.recommended_max],
            diagnostic_source,
            &"default_value"
        )

    if step < 0.0:
        result.add_error(
            &"property.definition.negative_step",
            "Editor step cannot be negative.",
            diagnostic_source,
            &"step",
            "Use 0 for continuous input or a positive editor increment."
        )

    if rationale.strip_edges().is_empty():
        result.add_warning(
            &"property.definition.missing_rationale",
            "Document why the default and recommended range are useful.",
            diagnostic_source,
            &"rationale"
        )

    return result


func validate_value(value: float, source: String = "") -> ValidationResult:
    var result := ValidationResult.new()
    var diagnostic_source := _diagnostic_source(source)

    if range == null or not range.is_definition_valid():
        result.add_error(
            &"property.value.invalid_definition",
            "Cannot validate a value against a missing or invalid RangeSpec.",
            diagnostic_source,
            &"range"
        )
        return result

    var status := range.status_for(value)
    match status:
        RangeSpec.ValueStatus.BELOW_HARD_MIN, RangeSpec.ValueStatus.ABOVE_HARD_MAX:
            result.add_error(
                &"property.value.out_of_bounds",
                "Value %s lies outside the legal hard range [%s, %s]." % [value, range.hard_min, range.hard_max],
                diagnostic_source,
                property_id,
                "Choose a value inside the hard range."
            )
        RangeSpec.ValueStatus.BELOW_RECOMMENDED, RangeSpec.ValueStatus.ABOVE_RECOMMENDED:
            result.add_warning(
                &"property.value.outside_recommended",
                "Value %s is legal but outside the recommended range [%s, %s]." % [value, range.recommended_min, range.recommended_max],
                diagnostic_source,
                property_id,
                consequences
            )

    return result


func clamp_to_legal_range(value: float) -> float:
    if range == null or not range.is_definition_valid():
        return value
    return range.clamp_to_hard_bounds(value)


func _diagnostic_source(explicit_source: String) -> String:
    if not explicit_source.is_empty():
        return explicit_source
    return String(property_id)
