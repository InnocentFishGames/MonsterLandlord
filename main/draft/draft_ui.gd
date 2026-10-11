class_name DraftUI
extends Control

# Emitted upward when one of our DraftChoice children is selected.
signal room_selected(room_resource: RoomResource)
signal room_drag_started(room_resource: RoomResource)
signal room_drag_released

# Scene used to create individual draft choices.
@export var draft_choice_scene: PackedScene

# Container that owns the generated DraftChoice nodes.
@export var choices_container: HBoxContainer

func _ready() -> void:
	if draft_choice_scene == null:
		push_error(
			"DraftUI: DraftChoice scene has not been assigned."
		)
		return

	if choices_container == null:
		push_error(
			"DraftUI: ChoicesContainer has not been assigned."
		)
		return

func show_draft(room_resources: Array[RoomResource]) -> void:

	if room_resources.is_empty():
		push_warning(
			"DraftUI: Cannot display an empty draft."
		)
		return

	clear_draft()

	for room_resource: RoomResource in room_resources:
		if room_resource == null:
			push_warning(
				"DraftUI: Draft contained a null RoomResource. Skipping it."
			)
			continue

		var choice_node: Node = draft_choice_scene.instantiate()

		if not choice_node is DraftChoice:
			push_error(
				"DraftUI: DraftChoice scene root must be a DraftChoice."
			)

			choice_node.queue_free()
			continue

		var draft_choice: DraftChoice = choice_node as DraftChoice

		choices_container.add_child(draft_choice)

		draft_choice.setup(room_resource)
		draft_choice.drag_released.connect(
			_on_draft_choice_drag_released
		)
		draft_choice.selected.connect(
			_on_draft_choice_selected
		)
		draft_choice.drag_started.connect(
			_on_draft_choice_drag_started
		)
		
func _on_draft_choice_drag_released() -> void:
	room_drag_released.emit()
		
func clear_draft() -> void:
	for child: Node in choices_container.get_children():
		child.queue_free()
		
func _on_draft_choice_selected(
	room_resource: RoomResource
) -> void:
	if room_resource == null:
		push_error(
			"DraftUI: Received a null RoomResource from DraftChoice."
		)
		return


	room_selected.emit(room_resource)

func _on_draft_choice_drag_started(
	room_resource: RoomResource
) -> void:
	if room_resource == null:
		push_error(
			"DraftUI: Received a null RoomResource when drag started."
		)
		return

	print("DraftUI received drag: ", room_resource.room_name)

	hide()

	room_drag_started.emit(room_resource)
	
	
