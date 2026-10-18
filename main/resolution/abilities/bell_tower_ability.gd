class_name BellTowerAbility
extends RoomAbility


# Used by: Bell Tower (data/rooms/bell_tower.tres).
# When the room resolves, the tenant in the next occupied room gets extra
# rent for the rest of this month's resolution. The bonus counts as base
# rent, so multipliers apply to it. If the Bell Tower resolves again
# (an Echo Room), the bonus stacks.

@export var rent_bonus: int = 5


func on_resolved(
	room_instance: RoomInstance,
	context: ResolutionContext,
	_resolution_manager: ResolutionManager,
	_result: RentResult
) -> void:
	var next_room: RoomInstance = context.get_next_room(room_instance)

	# The last occupied room has no next tenant to help.
	if next_room == null:
		return

	context.add_rent_bonus(next_room, rent_bonus)
