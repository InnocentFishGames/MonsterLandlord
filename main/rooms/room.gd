class_name Room
extends Node2D


var room_instance: RoomInstance = null
@export var tenant_visual: Node2D

func setup(new_room_instance: RoomInstance) -> void:
	if new_room_instance == null:
		push_error(
			"Room: Cannot setup room because RoomInstance is null."
		)
		return

	if new_room_instance.room_resource == null:
		push_error(
			"Room: Cannot setup room because RoomResource is null."
		)
		return
	if tenant_visual == null:
		push_error(
			"Room: Cannot setup because TenantVisual is not assigned."
		)
		return
		
	room_instance = new_room_instance
	_update_tenant_visual()

	queue_redraw()

func _update_tenant_visual() -> void:
	if room_instance == null:
		tenant_visual.hide()
		return

	if room_instance.is_occupied():
		tenant_visual.show()
	else:
		tenant_visual.hide()
		
		
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
