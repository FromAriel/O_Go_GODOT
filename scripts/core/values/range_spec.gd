class_name RangeSpec
extends Resource

## Reusable numeric bounds primitive.
##
## The neutral defaults describe a conventional normalized interval [0, 1].
## They are defaults only, not engine-wide tuning assumptions. Later property
## metadata builds on this primitive with units, step size, rationale, and UI.

enum ValueStatus {
    BELOW_HARD_MIN,
    BELOW_RECOMMENDED,
    RECOMMENDED,
    ABOVE_RECOMMENDED,
    ABOVE_HARD_MAX,
}

@export var hard_min: float = 0.0
@export var hard_max: float = 1.0
@export var recommended_min: float = 0.0
@export var recommended_max: float = 1.0


func is_definition_valid() -> bool:
    return (
        hard_min <= recommended_min
        and recommended_min <= recommended_max
        and recommended_max <= hard_max
    )


func contains(value: float) -> bool:
    return value >= hard_min and value <= hard_max


func is_recommended(value: float) -> bool:
    return value >= recommended_min and value <= recommended_max


func clamp_to_hard_bounds(value: float) -> float:
    return clampf(value, hard_min, hard_max)


func status_for(value: float) -> int:
    if value < hard_min:
        return ValueStatus.BELOW_HARD_MIN
    if value < recommended_min:
        return ValueStatus.BELOW_RECOMMENDED
    if value <= recommended_max:
        return ValueStatus.RECOMMENDED
    if value <= hard_max:
        return ValueStatus.ABOVE_RECOMMENDED
    return ValueStatus.ABOVE_HARD_MAX
