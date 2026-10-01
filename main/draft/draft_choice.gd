class_name DraftChoice
extends Button

# We send the RoomResource upward rather than telling another system
# what to do with it. 
signal selected(room_resource: RoomResource)

# References to the UI elements owned by this DraftChoice.
# They are assigned through the Inspector so this script does not
# depend on hardcoded NodePaths.
@export var name_label: Label
@export var rarity_label: Label
@export var size_label: Label

var room_resource: RoomResource


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


func setup(new_room_resource: RoomResource) -> void:
	if new_room_resource == null:
		push_error(
			"DraftChoice: Cannot setup a draft choice with a null RoomResource."
		)
		return

	room_resource = new_room_resource

	name_label.text = room_resource.name

	size_label.text = "%d x %d" % [
		room_resource.size.x,
		room_resource.size.y
	]

	rarity_label.text = RoomResource.Rarity.keys()[
		room_resource.rarity
	]

func _on_pressed() -> void:
	if room_resource == null:
		push_error(
			"DraftChoice: Cannot select a choice without a RoomResource."
		)
		return

	selected.emit(room_resource)
