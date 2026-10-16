class_name DraftUI
extends Control


# Emitted upward when one of our DraftChoice children is selected.
signal tenant_drag_released()


# Scene used to create individual draft choices.
@export var draft_choice_scene: PackedScene

# Container that owns the generated DraftChoice nodes.
@export var choices_container: HBoxContainer


func initialize() -> bool:
	# Validate the Inspector dependencies owned by this UI.
	if draft_choice_scene == null:
		push_error(
			"DraftUI: DraftChoice scene has not been assigned."
		)
		return false

	if choices_container == null:
		push_error(
			"DraftUI: ChoicesContainer has not been assigned."
		)
		return false

	return true


func show_draft(
	tenant_resources: Array[TenantResource]
) -> bool:
	clear_draft()

	for tenant_resource: TenantResource in tenant_resources:
		var choice_node: Node = draft_choice_scene.instantiate()

		# The Inspector can contain a scene with the wrong root type.
		if choice_node is not DraftChoice:
			push_error(
				"DraftUI: DraftChoice scene root must be a DraftChoice."
			)
			choice_node.queue_free()
			clear_draft()
			return false

		var draft_choice: DraftChoice = choice_node as DraftChoice

		# Configure before adding the button to the active interface.
		if not draft_choice.setup(tenant_resource):
			draft_choice.queue_free()
			clear_draft()
			return false

		draft_choice.drag_released.connect(
			_on_draft_choice_drag_released
		)

		choices_container.add_child(draft_choice)

	return true

func clear_draft() -> void:
	for child: Node in choices_container.get_children():
		# Remove immediately so obsolete choices cannot remain active
		# while waiting for queue_free() to finish.
		choices_container.remove_child(child)
		child.queue_free()

func _on_draft_choice_drag_released() -> void:
	tenant_drag_released.emit()
