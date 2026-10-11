class_name RoomManager extends Node2D

# The grid this RoomManager is working with.
@export var grid_component: GridComponent
@export var room_scene: PackedScene
# All rooms currently belonging to this building.
# RoomManager owns this collection because managing rooms
# is its responsibility.
var rooms: Array[RoomInstance] = []

func add_room(room_instance: RoomInstance) -> bool:
	# Make sure we were given a valid RoomInstance.
	if room_instance == null:
		push_error("RoomManager: Cannot add a null RoomInstance.")
		return false
		
	# Every RoomInstance must reference a RoomResource.
	# The resource contains information RoomManager needs later,
	# such as the room's size.
	if room_instance.room_resource == null:
		push_error(
			"RoomManager: Cannot add RoomInstance because its RoomResource is null."
		)
		return false
		
	if room_scene == null:
		push_error("RoomManager: Room scene has not been assigned.")
		return false
		
	# We need the GridComponent to validate the room's position.
	if grid_component == null:
		push_error("RoomManager: Cannot add room because GridComponent is not assigned.")
		return false

	# First, check whether the entire room fits inside the building.
	if not can_place_room(
		room_instance.room_resource,
		room_instance.grid_position
	):
		push_error("RoomManager: Room overlaps an existing room.")
		return false

	# Next, check whether another room already occupies
	# any of the cells this room wants to use.
	
	# Create the visual Room scene.
	var room_node: Node = room_scene.instantiate()

	# Make sure the assigned scene actually contains a Room.
	if not room_node is Room:
		push_error("RoomManager: Room scene does not contain a Room node.")
		room_node.queue_free()
		return false

	# Convert the generic Node into our Room type.
	var room: Room = room_node as Room
	# Convert the room's logical grid position into a world position.
	var world_position: Vector2 = grid_component.grid_to_world_position(
		room_instance.grid_position
	)
	# Place the visual Room at that world position.
	room.position = world_position
	
	# Give the visual Room its logical RoomInstance.
	room.setup(room_instance)
	
	# The room passed all of our placement checks.
	rooms.append(room_instance)
	
	# Add the visual Room to the RoomManager.
	add_child(room)

	return true

func can_place_room(
	room_resource: RoomResource,
	grid_position: Vector2i
) -> bool:
	if room_resource == null:
		push_error(
			"RoomManager: Cannot check placement with a null RoomResource."
		)
		return false

	# Check every cell that the new room would occupy.
	for x: int in range(room_resource.size.x):
		for y: int in range(room_resource.size.y):
			var cell_position: Vector2i = (
				grid_position + Vector2i(x, y)
			)

			if is_grid_position_occupied(cell_position):
				return false

	return true

func is_grid_position_occupied(
	grid_position: Vector2i
) -> bool:
	for room_instance: RoomInstance in rooms:
		if room_instance == null:
			push_warning(
				"RoomManager: Rooms contains a null RoomInstance."
			)
			continue

		var room_start: Vector2i = room_instance.grid_position
		var room_end: Vector2i = (
			room_start + room_instance.room_resource.size
		)

		if (
			grid_position.x >= room_start.x
			and grid_position.x < room_end.x
			and grid_position.y >= room_start.y
			and grid_position.y < room_end.y
		):
			return true

	return false
