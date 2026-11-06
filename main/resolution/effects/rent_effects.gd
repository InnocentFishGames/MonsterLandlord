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


# A short player-facing name, shown in the rent breakdown.
@abstract
func get_label() -> String
