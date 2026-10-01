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
	if not grid_component.can_fit_room(
		room_instance.grid_position,
		room_instance.room_resource.size
	):
		push_error("RoomManager: Room does not fit inside the building grid.")
		return false

	# Next, check whether another room already occupies
	# any of the cells this room wants to use.
	if not grid_component.is_room_position_available(
		room_instance,
		rooms
	):
		push_error("RoomManager: Room overlaps an existing room.")
		return false
	
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
