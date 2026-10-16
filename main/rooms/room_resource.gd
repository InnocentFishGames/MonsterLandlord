class_name RoomResource
extends Resource


@export var room_name: String = ""
@export var size: Vector2i = Vector2i.ONE
@export var rent_effects: Array[RentEffect] = []


func validate() -> bool:
	# Check Inspector-authored effects before this room enters gameplay.
	for index: int in range(rent_effects.size()):
		if rent_effects[index] == null:
			push_error(
				"RoomResource '%s': Rent effect slot %d is empty."
				% [room_name, index]
			)
			return false

	return true
