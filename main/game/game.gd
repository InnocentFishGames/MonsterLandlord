class_name Game
extends Node2D


# Major systems owned by this gameplay scene.
#
# Game knows which systems exist and is responsible for wiring their
# dependencies together.
@export var building: Building
@export var placement_controller: PlacementController
@export var draft_manager: DraftManager

func _ready() -> void:
	if building == null:
		push_error(
			"Game: Building has not been assigned in the Inspector."
		)
		return

	if placement_controller == null:
		push_error(
			"Game: PlacementController has not been assigned in the Inspector."
		)
		return

	if building.grid_component == null:
		push_error(
			"Game: Building does not have a GridComponent assigned."
		)
		return

	if building.room_container == null:
		push_error(
			"Game: Building does not have a RoomManager assigned."
		)
		return
	if draft_manager == null:
		push_error(
			"Game: DraftManager has not been assigned in the Inspector."
		)
		return
	placement_controller.placement_confirmed.connect(
		_on_placement_confirmed
	)
	placement_controller.setup(
		building.grid_component,
		building.room_container
	)
	draft_manager.room_drag_started.connect(
		_on_room_drag_started
	)
	draft_manager.room_drag_released.connect(
		_on_room_drag_released
	)

func _on_room_drag_released() -> void:
	placement_controller.release_placement()
	
func _on_room_drag_started(
	room_resource: RoomResource
) -> void:
	if room_resource == null:
		push_error(
			"Game: Cannot start placement with a null RoomResource."
		)
		return
	

	placement_controller.start_placement(
		room_resource
	)
func _on_placement_confirmed(
	room_instance: RoomInstance
) -> void:
	if room_instance == null:
		push_error(
			"Game: Cannot place room because room_instance is null."
		)
		return

	if building == null:
		push_error(
			"Game: Cannot place room because building is null."
		)
		return

	if building.room_container == null:
		push_error(
			"Game: Cannot place room because RoomManager is null."
		)
		return

	var was_added: bool = building.room_container.add_room(
		room_instance
	)

	if not was_added:
		push_error(
			"Game: RoomManager failed to add the confirmed room."
		)
		return

	placement_controller.finish_placement()
	
