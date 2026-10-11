class_name PlacementPreview
extends Node2D


var room_size: Vector2i = Vector2i.ONE
var cell_size: Vector2 = Vector2.ZERO
var is_valid: bool = false
func _ready() -> void:
	z_index = 100
func setup(
	new_room_size: Vector2i,
	new_cell_size: Vector2
) -> void:
	if new_room_size.x <= 0 or new_room_size.y <= 0:
		push_error(
			"PlacementPreview: Room size must be greater than zero."
		)
		return

	if new_cell_size.x <= 0.0 or new_cell_size.y <= 0.0:
		push_error(
			"PlacementPreview: Cell size must be greater than zero."
		)
		return

	room_size = new_room_size
	cell_size = new_cell_size

	queue_redraw()

func set_validity(new_is_valid: bool) -> void:
	if is_valid == new_is_valid:
		return

	is_valid = new_is_valid
	queue_redraw()

func _draw() -> void:

	if cell_size == Vector2.ZERO:
		return

	var preview_size: Vector2 = Vector2(
		room_size.x * cell_size.x,
		room_size.y * cell_size.y
	)
	var preview_color: Color

	if is_valid:
		preview_color = Color(0.2, 1.0, 0.2, 0.5)
	else:
		preview_color = Color(1.0, 0.2, 0.2, 0.5)

	draw_rect(
		Rect2(Vector2.ZERO, preview_size),
		preview_color
	)
