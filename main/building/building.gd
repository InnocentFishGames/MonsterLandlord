class_name Building extends Node2D

# The Building needs a GridComponent to understand its grid.
# We use an exported reference instead of:
# get_node("GridComponent")
# This keeps the Building decoupled from a specific node path.
@export var grid_component: GridComponent

# The Building also needs a RoomContainer.
# The Building can tell the RoomContainer what should happen,
# but the RoomContainer is responsible for managing the
# actual visual rooms.
@export var room_container: RoomManager


func _ready() -> void:
	# Make sure the required dependencies were assigned.
	# This gives us an obvious error during development
	# instead of getting a confusing null reference later.
	if grid_component == null:
		push_error("Building: GridComponent has not been assigned.")
		return

	if room_container == null:
		push_error("Building: RoomContainer has not been assigned.")
		return
	
	#test_room_visual_position()
##
#func test_room_visual_position() -> void:
	## Create a temporary RoomResource.
	#var room_resource: RoomResource = RoomResource.new()
#
	## Give the room a size of one grid cell.
	#room_resource.size = Vector2i(2, 1)
#
	## Create a RoomInstance at grid position (1, 0).
	#var room_instance: RoomInstance = RoomInstance.new(
		#room_resource,
		#Vector2i(1, 0)
	#)
#
	## Ask RoomManager to create the visual Room.
	#var was_added: bool = room_container.add_room(room_instance)
#
	#if not was_added:
		#push_error("Building test: Room failed to be added.")
		#return
#
	#print("Building test: Room added successfully.")
