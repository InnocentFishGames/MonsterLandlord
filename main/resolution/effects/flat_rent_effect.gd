class_name FlatRentEffect
extends RentEffect


@export var rent_bonus: int = 5


func get_stage() -> Stage:
	# Flat bonuses are applied before rent multipliers.

	return Stage.ADDITIVE


func apply(
	current_rent: int,
	_room_instance: RoomInstance,
	_context: ResolutionContext
) -> int:
	# Adds a fixed amount to the rent accumulated so far.

	return current_rent + rent_bonus
