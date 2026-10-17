class_name Room
extends Node2D


signal tenant_assigned(
	tenant_instance: TenantInstance
)
signal tenant_hovered(
	room_instance: RoomInstance,
	tenant_resource: TenantResource
)
# Reports which room the pointer has left.
signal tenant_hover_ended(room_instance: RoomInstance)


var room_instance: RoomInstance = null
# Full room dimensions in pixels, supplied by RoomManager.
var pixel_size: Vector2 = Vector2.ZERO


# Use the specific type because Room calls TenantVisual.setup().
@export var tenant_visual: TenantVisual
@export var tenant_drop_area: TenantDropArea
@export var tenant_name_label: Label


func setup(
	new_room_instance: RoomInstance,
	new_pixel_size: Vector2
) -> bool:
	# Validate incoming room data.
	if new_room_instance == null:
		push_error(
			"Room: Cannot setup because RoomInstance is null."
		)
		return false

	if new_room_instance.room_resource == null:
		push_error(
			"Room: Cannot setup because RoomResource is null."
		)
		return false

	# Validate Inspector dependencies once during setup.
	if tenant_visual == null:
		push_error(
			"Room: TenantVisual has not been assigned."
		)
		return false

	if tenant_drop_area == null:
		push_error(
			"Room: TenantDropArea has not been assigned."
		)
		return false

	if tenant_name_label == null:
		push_error(
			"Room: TenantNameLabel has not been assigned."
		)
		return false
	# Dimensions enter Room through setup, so validate them here.
	if new_pixel_size.x <= 0.0 or new_pixel_size.y <= 0.0:
		push_error(
			"Room: Pixel dimensions must be greater than zero."
		)
		return false
	room_instance = new_room_instance
	pixel_size = new_pixel_size
	# Position the tenant at the center of the full room footprint.
	# This works for both single-cell and larger rooms.
	tenant_visual.position = pixel_size * 0.5
	# Match the interactive area to the entire room footprint.
	# Set the minimum first so an old minimum cannot prevent shrinking.
	tenant_drop_area.custom_minimum_size = pixel_size
	tenant_drop_area.size = pixel_size
	
	tenant_drop_area.tenant_dropped.connect(
		_on_tenant_dropped
	)
	tenant_drop_area.tenant_hovered.connect(
		_on_tenant_hovered
	)
	# Use Control's existing mouse-exit signal.
	tenant_drop_area.mouse_exited.connect(
		_on_tenant_drop_area_mouse_exited
	)
	_update_tenant_visual()

	queue_redraw()
	# Configuration and initial display setup completed successfully.
	return true


func _on_tenant_dropped(
	tenant_resource: TenantResource
) -> void:

	var tenant_instance: TenantInstance = TenantInstance.new(
		tenant_resource
	)

	var was_assigned: bool = room_instance.assign_tenant(
		tenant_instance
	)

	if not was_assigned:
		return

	_update_tenant_visual()

	tenant_assigned.emit(tenant_instance)


func _update_tenant_visual() -> void:
	# Keep drop availability synchronized with actual occupancy.
	tenant_drop_area.accepts_tenant = not room_instance.is_occupied()

	# Empty rooms have no tenant name or visible tenant.
	if not room_instance.is_occupied():
		tenant_name_label.text = ""
		tenant_visual.hide()
		return

	var tenant_instance: TenantInstance = (
		room_instance.tenant_instance
	)

	tenant_name_label.text = (
		tenant_instance.tenant_resource.tenant_name
	)

	# Supply the assigned tenant before displaying its visual.
	# setup() also requests a redraw.
	tenant_visual.setup(tenant_instance)
	tenant_visual.show()


func remove_tenant() -> TenantInstance:
	if not room_instance.is_occupied():
		return null

	var removed_tenant: TenantInstance = (
		room_instance.remove_tenant()
	)

	_update_tenant_visual()

	return removed_tenant


func _draw() -> void:
	# Drawing can occur before setup has supplied room data.
	if room_instance == null:
		return

	draw_rect(
		Rect2(Vector2.ZERO, pixel_size),
		Color.DARK_GRAY,
		true
	)

func _on_tenant_hovered(
	tenant_resource: TenantResource
) -> void:

	tenant_hovered.emit(
		room_instance,
		tenant_resource
	)
func _on_tenant_drop_area_mouse_exited() -> void:
	tenant_hover_ended.emit(room_instance)
