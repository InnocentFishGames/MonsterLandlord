@abstract
class_name RoomAbility
extends Resource


# A room ability changes how resolution flows, instead of changing one
# room's rent number (that is what a RentEffect does). Each ability is its
# own script, named after the room that uses it, e.g. EchoRoomAbility.
#
# Abilities are definitions and must stay read-only. Anything they change
# during a resolution goes into the ResolutionContext or the RentResult.


# Called right after room_instance has paid its rent in a resolution.
@abstract
func on_resolved(
	room_instance: RoomInstance,
	context: ResolutionContext,
	resolution_manager: ResolutionManager,
	result: RentResult
) -> void
