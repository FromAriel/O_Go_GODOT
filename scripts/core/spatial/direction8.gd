class_name Direction8
extends RefCounted

## Shared eight-direction representation for actors, movement intent, animation,
## and interaction facing. NONE represents no directional intent.

enum Value {
    NONE,
    NORTH,
    NORTH_EAST,
    EAST,
    SOUTH_EAST,
    SOUTH,
    SOUTH_WEST,
    WEST,
    NORTH_WEST,
}

# Exact geometric component of a normalized 45-degree diagonal: 1 / sqrt(2).
# This is mathematical rather than designer tuning. Changing it would make
# diagonal direction vectors non-unit length and should not be exposed as data.
const DIAGONAL_COMPONENT := 0.7071067811865476


static func from_vector(vector: Vector2) -> int:
    if vector.is_zero_approx():
        return Value.NONE

    var signs := Vector2i(signi(int(signf(vector.x))), signi(int(signf(vector.y))))
    match signs:
        Vector2i(0, -1):
            return Value.NORTH
        Vector2i(1, -1):
            return Value.NORTH_EAST
        Vector2i(1, 0):
            return Value.EAST
        Vector2i(1, 1):
            return Value.SOUTH_EAST
        Vector2i(0, 1):
            return Value.SOUTH
        Vector2i(-1, 1):
            return Value.SOUTH_WEST
        Vector2i(-1, 0):
            return Value.WEST
        Vector2i(-1, -1):
            return Value.NORTH_WEST
        _:
            return Value.NONE


static func to_vector(direction: int) -> Vector2:
    match direction:
        Value.NORTH:
            return Vector2.UP
        Value.NORTH_EAST:
            return Vector2(DIAGONAL_COMPONENT, -DIAGONAL_COMPONENT)
        Value.EAST:
            return Vector2.RIGHT
        Value.SOUTH_EAST:
            return Vector2(DIAGONAL_COMPONENT, DIAGONAL_COMPONENT)
        Value.SOUTH:
            return Vector2.DOWN
        Value.SOUTH_WEST:
            return Vector2(-DIAGONAL_COMPONENT, DIAGONAL_COMPONENT)
        Value.WEST:
            return Vector2.LEFT
        Value.NORTH_WEST:
            return Vector2(-DIAGONAL_COMPONENT, -DIAGONAL_COMPONENT)
        _:
            return Vector2.ZERO
