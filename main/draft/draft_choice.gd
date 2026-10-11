class_name DraftChoice
extends Button


signal drag_started(tenant_resource: TenantResource)
signal drag_released
signal selected(tenant_resource: TenantResource)


# References to the UI elements owned by this DraftChoice.
# They are assigned through the Inspector so this script does not
# depend on hardcoded NodePaths.
@export var name_label: Label
@export var rarity_label: Label
@export var size_label: Label


var tenant_resource: TenantResource = null


func _ready() -> void:
	if name_label == null:
		push_error(
			"DraftChoice: NameLabel has not been assigned in the Inspector."
		)
		return

	if rarity_label == null:
		push_error(
			"DraftChoice: RarityLabel has not been assigned in the Inspector."
		)
		return

	if size_label == null:
		push_error(
			"DraftChoice: SizeLabel has not been assigned in the Inspector."
		)
		return

	# Size belonged to rooms, not tenants.
	# Keep the UI element for now, but hide it.
	size_label.hide()

	pressed.connect(_on_pressed)


func setup(new_tenant_resource: TenantResource) -> void:
	if new_tenant_resource == null:
		push_error(
			"DraftChoice: Cannot setup a draft choice with a null TenantResource."
		)
		return

	tenant_resource = new_tenant_resource

	name_label.text = tenant_resource.tenant_name

	rarity_label.text = TenantResource.Rarity.keys()[
		tenant_resource.rarity
	]


func _on_pressed() -> void:
	if tenant_resource == null:
		push_error(
			"DraftChoice: Cannot select a choice without a TenantResource."
		)
		return

	selected.emit(tenant_resource)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if tenant_resource == null:
		push_error(
			"DraftChoice: Cannot start drag because TenantResource is null."
		)
		return null

	drag_started.emit(tenant_resource)

	return tenant_resource


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return

	drag_released.emit()










#class_name DraftChoice
#extends Button
#
#signal drag_started(room_resource: RoomResource)
#signal drag_released
#signal selected(room_resource: RoomResource)
## References to the UI elements owned by this DraftChoice.
## They are assigned through the Inspector so this script does not
## depend on hardcoded NodePaths.
#@export var name_label: Label
#@export var rarity_label: Label
#@export var size_label: Label
#
#var room_resource: RoomResource
#
#func _ready() -> void:
	#if name_label == null:
		#push_error(
			#"DraftChoice: NameLabel has not been assigned in the Inspector."
		#)
		#return
#
	#if rarity_label == null:
		#push_error(
			#"DraftChoice: RarityLabel has not been assigned in the Inspector."
		#)
		#return
#
	#if size_label == null:
		#push_error(
			#"DraftChoice: SizeLabel has not been assigned in the Inspector."
		#)
		#return
	#pressed.connect(_on_pressed)
#
#func setup(new_room_resource: RoomResource) -> void:
	#if new_room_resource == null:
		#push_error(
			#"DraftChoice: Cannot setup a draft choice with a null RoomResource."
		#)
		#return
#
	#room_resource = new_room_resource
#
	#name_label.text = room_resource.room_name
#
	#size_label.text = "%d x %d" % [
		#room_resource.size.x,
		#room_resource.size.y
	#]
#
#
#func _on_pressed() -> void:
	#if room_resource == null:
		#push_error(
			#"DraftChoice: Cannot select a choice without a RoomResource."
		#)
		#return
#
	#selected.emit(room_resource)
#
#func _get_drag_data(_at_position: Vector2) -> Variant:
#
	#if room_resource == null:
		#push_error(
			#"DraftChoice: Cannot start drag because RoomResource is null."
		#)
		#return null
#
	#drag_started.emit(room_resource)
#
	#return room_resource
#
#func _notification(what: int) -> void:
	#if what != NOTIFICATION_DRAG_END:
		#return
#
	#drag_released.emit()
