class_name DraftManager
extends Node

# Emitted after the player chooses one of the offered RoomResources.
# DraftManager does not decide what happens to the selected room next.
# A higher-level system can listen for this signal and decide what to do.
signal room_selected(room_resource: RoomResource)
signal room_drag_started(room_resource: RoomResource)
signal room_drag_released

# The RoomResources that are currently allowed to appear in a draft.
@export var available_rooms: Array[RoomResource] = []
@export var draft_ui: DraftUI

const DRAFT_CHOICE_COUNT: int = 3

func _ready() -> void:
	if draft_ui == null:
		push_error(
			"DraftManager: DraftUI has not been assigned in the Inspector."
		)
		return

	# A normal draft requires at least three available RoomResources.
	if available_rooms.size() < DRAFT_CHOICE_COUNT:
		push_error(
			"DraftManager: At least %d RoomResources are required to create a draft."
			% DRAFT_CHOICE_COUNT
		)
		return
	for room_resource: RoomResource in available_rooms:
		if room_resource == null:
			push_error(
				"DraftManager: Available Rooms contains an empty RoomResource slot."
			)
			return
	draft_ui.room_selected.connect(
	_on_room_selected
	)
	draft_ui.room_drag_started.connect(
		_on_room_drag_started
	)
	create_draft()
	
	draft_ui.room_drag_released.connect(
	_on_room_drag_released
)
	
func _on_room_drag_released() -> void:
	room_drag_released.emit()
	
func _on_room_drag_started(
	room_resource: RoomResource
) -> void:
	if room_resource == null:
		push_error(
			"DraftManager: DraftUI returned a null RoomResource when drag started."
		)
		return

	room_drag_started.emit(room_resource)
	
	
func _on_room_selected(room_resource: RoomResource) -> void:
	if room_resource == null:
		push_error(
			"DraftManager: DraftUI returned a null RoomResource."
		)
		return

	print("Selected RoomResource: ", room_resource.room_name)
	room_selected.emit(room_resource)
	
func create_draft() -> void:
	if draft_ui == null:
		push_error(
			"DraftManager: Cannot create draft because DraftUI is missing."
		)
		return

	if available_rooms.size() < DRAFT_CHOICE_COUNT:
		push_error(
			"DraftManager: Not enough RoomResources to create a draft."
		)
		return

	var draft_pool: Array[RoomResource] = available_rooms.duplicate()
	var choices: Array[RoomResource] = []

	for index: int in range(DRAFT_CHOICE_COUNT):
		var random_index: int = randi_range(
			0,
			draft_pool.size() - 1
		)

		var room_resource: RoomResource = draft_pool[random_index]

		choices.append(room_resource)

		# Remove this resource from the temporary pool so the exact
		# same RoomResource cannot appear twice in this draft.
		draft_pool.remove_at(random_index)

	draft_ui.show_draft(choices)
