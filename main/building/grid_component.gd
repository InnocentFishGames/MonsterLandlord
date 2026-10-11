class_name GridComponent extends Node2D

# Number of rooms that can fit horizontally/vertically.
@export var columns: int = 3
@export var rows: int = 3

# The size of one room in the world in pixels
@export var grid_size: Vector2 = Vector2(256, 256)

func _ready() -> void:
	queue_redraw()
	
func grid_to_world_position(grid_position: Vector2i) -> Vector2:
	# Convert a logical grid position into a world position
	#Rooms only need to know their grid position.The Building handles the actual pixel position.
	# Grid (0, 0) -> World (0, 0)
	# Grid (2, 2) -> World (512, 512)

	return Vector2(
		grid_position.x * grid_size.x,
		grid_position.y * grid_size.y,
	)

func world_to_grid_position(world_position: Vector2) -> Vector2i:
#takes mouse position as world_position anmd returns grid position
	return Vector2i(
		floor(world_position.x / grid_size.x),
		floor(world_position.y / grid_size.y),
	)

func is_valid_grid_position(grid_position: Vector2i) -> bool:
	# Check whether a grid position exists inside the building.
	if grid_position.x < 0:
		return false

	if grid_position.x >= columns:
		return false

	if grid_position.y < 0:
		return false

	if grid_position.y >= rows:
		return false

	return true
	
func can_fit_room(
	grid_position: Vector2i,
	room_size: Vector2i
) -> bool:
	# Check that the room has a valid size.
	if room_size.x <= 0 or room_size.y <= 0:
		return false

	# Calculate the last grid cell the room would occupy.
	var end_position: Vector2i = grid_position + room_size - Vector2i.ONE

	# Check both corners of the room.
	if not is_valid_grid_position(grid_position):
		return false

	if not is_valid_grid_position(end_position):
		return false

	return true
	

func get_building_size() -> Vector2:
	# Return the total pixel size of the building.
	# So our 3x3 building is 768x768 pixels.

	return Vector2(
		columns * grid_size.x,
		rows * grid_size.y
	)

func _draw() -> void:
	# This draws a simple temporary grid so we can actually
	# see our building while developing it.
	# Later we'll replace this with proper floor/wall artwork.

	var building_size: Vector2 = get_building_size()

	# Draw vertical grid lines.
	for x in range(columns + 1):
		var x_position: float = x * grid_size.x

		draw_line(
			Vector2(x_position, 0),
			Vector2(x_position, building_size.y),
			Color.WHITE,
			2.0
		)

	# Draw horizontal grid lines.
	for y in range(rows + 1):
		var y_position: float = y * grid_size.y

		draw_line(
			Vector2(0, y_position),
			Vector2(building_size.x, y_position),
			Color.WHITE,
			2.0
		)
