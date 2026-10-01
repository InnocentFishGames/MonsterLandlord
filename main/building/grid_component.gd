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
	
func is_room_position_available(
	room_instance: RoomInstance,
	rooms: Array[RoomInstance]
) -> bool:
	if room_instance == null:
		return false

	var room_position: Vector2i = room_instance.grid_position
	var room_size: Vector2i = room_instance.room_resource.size

	# Check every cell that the new room would occupy.
	for y: int in range(room_size.y):
		for x: int in range(room_size.x):
			var grid_position: Vector2i = room_position + Vector2i(x, y)

			# Check this cell against every room that is
			# already inside the building.
			for existing_room: RoomInstance in rooms:
				# Get the position of the existing room.
				var existing_position: Vector2i = existing_room.grid_position

				# Get the size of the existing room.
				var existing_size: Vector2i = existing_room.room_resource.size

				# Calculate the grid position immediately after
				# the existing room's occupied area.
				var existing_end: Vector2i = existing_position + existing_size

				# Determine whether the cell we're checking
				# falls inside the existing room.
				var is_occupied: bool = (
					grid_position.x >= existing_position.x
					and grid_position.x < existing_end.x
					and grid_position.y >= existing_position.y
					and grid_position.y < existing_end.y
				)
				# If even one cell is occupied, the new room
				# cannot be placed here.
				if is_occupied:
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
