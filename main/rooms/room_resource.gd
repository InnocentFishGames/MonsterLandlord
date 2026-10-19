class_name RoomResource
extends Resource


@export var room_name: String = ""
@export var size: Vector2i = Vector2i.ONE
# Cost in the between-month shop, and the text shown on its offer card.
@export var price: int = 10
@export_multiline var description: String = ""
@export var rent_effects: Array[RentEffect] = []
# Abilities that change how resolution flows (see RoomAbility), e.g. the
# Echo Room or Bell Tower. Rent effects above change this room's rent.
@export var abilities: Array[RoomAbility] = []


func validate() -> bool:
	if price < 0:
		push_error(
			"RoomResource '%s': Price cannot be negative."
			% room_name
		)
		return false

	# Check Inspector-authored effects before this room enters gameplay.
	for index: int in range(rent_effects.size()):
		if rent_effects[index] == null:
			push_error(
				"RoomResource '%s': Rent effect slot %d is empty."
				% [room_name, index]
			)
			return false

	for index: int in range(abilities.size()):
		if abilities[index] == null:
			push_error(
				"RoomResource '%s': Ability slot %d is empty."
				% [room_name, index]
			)
			return false

	return true
