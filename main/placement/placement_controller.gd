class_name PlacementController
extends Node2D

signal placement_confirmed(room_instance: RoomInstance)

signal placement_cancelled

@export var placement_preview: PlacementPreview
@export var placement_controls: Control
@export var confirm_button: Button
@export var cancel_button: Button

var is_pending_placement: bool = false
var is_current_position_valid: bool = false
var grid_component: GridComponent
var room_manager: RoomManager

var room_resource: RoomResource = null
# Grid cell currently underneath the mouse.
var current_grid_position: Vector2i = Vector2i.ZERO


func setup(
	new_grid_component: GridComponent,
	new_room_manager: RoomManager
) -> void:
	if new_grid_component == null:
		push_error(
			"PlacementController: Cannot setup without a GridComponent."
		)
		return

	if new_room_manager == null:
		push_error(
			"PlacementController: Cannot setup without a RoomManager."
		)
		return
	if placement_preview == null:
		push_error(
			"PlacementController: PlacementPreview has not been assigned."
		)
		return
	if placement_controls == null:
		push_error(
			"PlacementController: placement_controls is not assigned."
		)
		return

	if confirm_button == null:
		push_error(
			"PlacementController: confirm_button is not assigned."
		)
		return

	if cancel_button == null:
		push_error(
			"PlacementController: cancel_button is not assigned."
		)
		return
	confirm_button.pressed.connect(
		_on_confirm_button_pressed
	)

	cancel_button.pressed.connect(
		_on_cancel_button_pressed
	)
	placement_preview.hide()
	placement_controls.hide()
	grid_component = new_grid_component
	room_manager = new_room_manager

func _process(_delta: float) -> void:
	if grid_component == null:
		return

	if room_resource == null:
		return
	# Once the player releases the room onto a valid cell,
	# freeze the preview there while waiting for confirmation.
	if is_pending_placement:
		return

	var mouse_position: Vector2 = get_global_mouse_position()

	current_grid_position = grid_component.world_to_grid_position(
		mouse_position
	)

	placement_preview.global_position = (
		grid_component.grid_to_world_position(
			current_grid_position
		)
	)
	var fits_inside_grid: bool = grid_component.can_fit_room(
	current_grid_position,
	room_resource.size
)
	var position_available: bool = room_manager.can_place_room(
		room_resource,
		current_grid_position
	)

	is_current_position_valid = (
		fits_inside_grid
		and position_available
	)

	placement_preview.set_validity(
		is_current_position_valid
	)
	
func start_placement(new_room_resource: RoomResource) -> void:
	if new_room_resource == null:
		push_error(
			"PlacementController: Cannot start placement with a null RoomResource."
		)
		return	
#This check prevents something like
#Currently placing: Vampire
#
#↓ another request arrives
#
#Start placing: Human
	if room_resource != null:
		push_warning(
			"PlacementController: Cannot start a new placement while another placement is active."
		)
		return

	room_resource = new_room_resource
	
	placement_preview.setup(
	room_resource.size,
	grid_component.grid_size
)
	placement_preview.show()

func release_placement() -> void:
	if room_resource == null:
		push_warning(
			"PlacementController: Cannot release placement because no room is being placed."
		)
		return

	if not is_current_position_valid:
		return

	is_pending_placement = true

	placement_controls.show()

func _unhandled_input(event: InputEvent) -> void:
	if room_resource == null:
		return

	if event is not InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	# The room is currently pending.
	# Pressing the mouse picks it back up.
	if is_pending_placement:
		if mouse_event.pressed and _is_mouse_over_preview():
			is_pending_placement = false
			placement_controls.hide()

		return

	# The room is currently following the mouse.
	# Releasing it over a valid position makes it pending again.
	if not mouse_event.pressed:
		release_placement()

func _is_mouse_over_preview() -> bool:
	if room_resource == null:
		return false

	if grid_component == null:
		return false

	var preview_size: Vector2 = Vector2(
		room_resource.size.x * grid_component.grid_size.x,
		room_resource.size.y * grid_component.grid_size.y
	)

	var preview_rect: Rect2 = Rect2(
		placement_preview.global_position,
		preview_size
	)

	return preview_rect.has_point(
		get_global_mouse_position()
	)
	
func _on_cancel_button_pressed() -> void:
	if room_resource == null:
		push_warning(
			"PlacementController: Cannot cancel because no room is being placed."
		)
		return

	_clear_placement()

	placement_cancelled.emit()
	
func _on_confirm_button_pressed() -> void:
	if room_resource == null:
		push_error(
			"PlacementController: Cannot confirm because no room is being placed."
		)
		return

	if not is_pending_placement:
		push_warning(
			"PlacementController: Cannot confirm because placement is not pending."
		)
		return

	var room_instance: RoomInstance = RoomInstance.new(
		room_resource,
		current_grid_position
	)

	placement_confirmed.emit(room_instance)
	
func finish_placement() -> void:
	if room_resource == null:
		push_warning(
			"PlacementController: Cannot finish because no room is being placed."
		)
		return

	_clear_placement()
	
func _clear_placement() -> void:
	room_resource = null

	current_grid_position = Vector2i.ZERO
	is_current_position_valid = false
	is_pending_placement = false

	placement_preview.hide()
	placement_controls.hide()
