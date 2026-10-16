@abstract
class_name RentEffect
extends Resource


enum Stage {
	ADDITIVE,
	MULTIPLICATIVE,
	FINAL
}


@abstract
func get_stage() -> Stage


@abstract
func apply(
	current_rent: int,
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int
