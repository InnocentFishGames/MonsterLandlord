class_name Room
extends Node2D

# The logical room data that this visual Room represents.
var room_instance: RoomInstance


func setup(instance: RoomInstance) -> void:
	# Make sure we were given a valid RoomInstance.
	if instance == null:
		push_error("Room: Cannot setup with a null RoomInstance.")
		return

	# Store the logical room this visual object represents.
	room_instance = instance

	# Redraw the Room now that we know its size.
	queue_redraw()


func _draw() -> void:
	# We cannot draw anything until the Room has been given
	# a RoomInstance.
	if room_instance == null:
		return

	# Get the logical size of this room.
	var room_size: Vector2i = room_instance.room_resource.size

	# Convert the number of grid cells into a pixel size.
	#
	# For example:
	# 1 x 1 room = 256 x 256 pixels
	# 2 x 1 room = 512 x 256 pixels
	# 2 x 2 room = 512 x 512 pixels
	var pixel_size: Vector2 = Vector2(
		room_size.x * 256.0,
		room_size.y * 256.0
	)

	# Draw a simple temporary rectangle.
	draw_rect(
		Rect2(Vector2.ZERO, pixel_size),
		Color.DARK_GRAY,
		true
	)
