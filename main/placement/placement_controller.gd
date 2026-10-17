class_name PlacementController
extends Node2D


signal placement_confirmed(room_instance: RoomInstance)
signal placement_cancelled


@export var placement_preview: PlacementPreview
@export var placement_controls: Control
@export var confirm_button: Button
@export var cancel_button: Button


var grid_component: GridComponent
var room_manager: RoomManager

var room_resource: RoomResource = null

var current_grid_position: Vector2i = Vector2i.ZERO
var is_current_position_valid: bool = false
var is_pending_placement: bool = false


func setup(
	new_grid_component: GridComponent,
	new_room_manager: RoomManager
) -> bool:
	# Validate dependencies entering this component.
	if new_grid_component == null:
		push_error(
			"PlacementController: Cannot setup without a GridComponent."
		)
		return false

	if new_room_manager == null:
		push_error(
			"PlacementController: Cannot setup without a RoomManager."
		)
		return false

	# Validate Inspector dependencies once during setup.
	if placement_preview == null:
		push_error(
			"PlacementController: PlacementPreview has not been assigned."
		)
		return false

	if placement_controls == null:
		push_error(
			"PlacementController: PlacementControls has not been assigned."
		)
		return false

	if confirm_button == null:
		push_error(
			"PlacementController: ConfirmButton has not been assigned."
		)
		return false

	if cancel_button == null:
		push_error(
			"PlacementController: CancelButton has not been assigned."
		)
		return false

	grid_component = new_grid_component
	room_manager = new_room_manager

	confirm_button.pressed.connect(
		_on_confirm_button_pressed
	)

	cancel_button.pressed.connect(
		_on_cancel_button_pressed
	)

	placement_preview.hide()
	placement_controls.hide()
	# Dependencies are assigned and controls are connected.
	return true

func _process(_delta: float) -> void:
	# No placement is active.
	if room_resource == null:
		return

	# The room has been released and is waiting for confirmation,
	# so the preview should no longer follow the mouse.
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

	# RoomManager checks both grid bounds and overlap.
	is_current_position_valid = room_manager.can_place_room(
		room_resource,
		current_grid_position
	)
	
	placement_preview.set_validity(
		is_current_position_valid
	)


func start_placement(
	new_room_resource: RoomResource
) -> bool:
	# RoomResource enters the component here.
	if new_room_resource == null:
		push_error(
			"PlacementController: Cannot start placement with a null RoomResource."
		)
		return false

	# Cannot start another placement while one is already active.
	if room_resource != null:
		return false

	# Configure the preview before activating placement.
	# If dimensions are invalid, leave placement inactive.
	if not placement_preview.setup(
		new_room_resource.size,
		grid_component.grid_size
	):
		return false

	room_resource = new_room_resource

	placement_preview.show()
	return true

func release_placement() -> void:
	# Releasing without an active placement is an invalid state transition.
	if room_resource == null:
		push_warning(
			"PlacementController: Cannot release because no room is being placed."
		)
		return

	# An invalid grid position simply cannot become pending.
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

	# Clicking the pending preview picks the room back up.
	if is_pending_placement:
		if mouse_event.pressed and _is_mouse_over_preview():
			is_pending_placement = false
			placement_controls.hide()

		return

	# Releasing while following the mouse attempts to place the room.
	if not mouse_event.pressed:
		release_placement()


func _is_mouse_over_preview() -> bool:
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
		push_warning(
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
