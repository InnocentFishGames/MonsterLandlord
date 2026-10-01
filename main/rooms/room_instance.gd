class_name RoomInstance
extends RefCounted

# The room definition this instance is based on.
var room_resource: RoomResource

# Where this room is currently placed on the building grid.
var grid_position: Vector2i

func _init(resource: RoomResource, position: Vector2i) -> void:
	room_resource = resource
	grid_position = position
