class_name DraftChoice
extends Button


signal drag_released()


# References to the UI elements owned by this DraftChoice.
# They are assigned through the Inspector so this script does not
# depend on hardcoded NodePaths.
@export var name_label: Label
@export var rarity_label: Label


var tenant_resource: TenantResource = null


func setup(new_tenant_resource: TenantResource) -> bool:
	# Validate the Inspector references owned by this choice.
	if name_label == null:
		push_error(
			"DraftChoice: NameLabel has not been assigned."
		)
		return false

	if rarity_label == null:
		push_error(
			"DraftChoice: RarityLabel has not been assigned."
		)
		return false

	# DraftManager has already validated the tenant pool.
	tenant_resource = new_tenant_resource

	name_label.text = tenant_resource.tenant_name
	rarity_label.text = TenantResource.Rarity.keys()[
		tenant_resource.rarity
	]

	return true


func _get_drag_data(_at_position: Vector2) -> Variant:
	
	# Create a temporary visual that follows the mouse while dragging.
	var preview: Label = Label.new()
	preview.text = tenant_resource.tenant_name

	# Godot owns this preview after it is assigned.
	# We do not need to manually free it.
	set_drag_preview(preview)

	return tenant_resource

func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return

	drag_released.emit()
