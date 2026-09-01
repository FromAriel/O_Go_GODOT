class_name SpatialConventions
extends RefCounted

## Shared coordinate conventions.
##
## World positions use Vector2 pixels in Godot's normal 2D coordinate system:
## origin at the upper-left, +X to the right, +Y downward.
## Grid positions use Vector2i cell coordinates in the same orientation.
## Tile/cell size is supplied by project data; this module never assumes 32px.


static func grid_to_world_origin(grid_position: Vector2i, cell_size: Vector2i) -> Vector2:
    _assert_valid_cell_size(cell_size)
    return Vector2(grid_position * cell_size)


static func world_to_grid_floor(world_position: Vector2, cell_size: Vector2i) -> Vector2i:
    _assert_valid_cell_size(cell_size)
    return Vector2i(
        floori(world_position.x / float(cell_size.x)),
        floori(world_position.y / float(cell_size.y))
    )


static func _assert_valid_cell_size(cell_size: Vector2i) -> void:
    assert(
        cell_size.x > 0 and cell_size.y > 0,
        "Cell size must be positive on both axes."
    )
