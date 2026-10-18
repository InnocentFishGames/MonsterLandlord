class_name EchoRoomAbility
extends RoomAbility


# Used by: Echo Room (data/rooms/echo_room.tres).
# When the room resolves, the nearest earlier occupied room resolves again
# with its own tenant, neighbors and room effects. If that room is an Echo
# Room too, it echoes its own earlier room, so the chain cascades. Every step
# goes strictly earlier, so it always ends. The first occupied room has no
# earlier room, so nothing happens.


func on_resolved(
	room_instance: RoomInstance,
	context: ResolutionContext,
	resolution_manager: ResolutionManager,
	result: RentResult
) -> void:
	var previous_room: RoomInstance = context.get_previous_room(
		room_instance
	)

	if previous_room == null:
		return

	resolution_manager.resolve_room(
		previous_room,
		" (replay)",
		context,
		result
	)
