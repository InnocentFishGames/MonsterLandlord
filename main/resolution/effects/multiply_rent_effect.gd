class_name MultiplyRentEffect
extends RentEffect


@export var multiplier: float = 2.0


func get_stage() -> Stage:
	# Multipliers resolve after additive bonuses.

	return Stage.MULTIPLICATIVE


func apply(
	current_rent: int,
	_room_instance: RoomInstance,
	_context: ResolutionContext
) -> int:
	# Multiplies all rent accumulated before this effect.

	var modified_rent: float = (
		float(current_rent) * multiplier
	)

	return roundi(modified_rent)
