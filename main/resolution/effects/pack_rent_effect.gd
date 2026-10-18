class_name PackRentEffect
extends RentEffect


# Used by: Werewolf (data/tenants/werewolf.tres), "Pack Mentality".
# If every room on this tenant's row holds a tenant with the chosen tag,
# the rent is multiplied. An empty room or any other tenant on the row
# breaks the pack. Rooms that were never built do not count.

@export var tag: TenantResource.Tag = TenantResource.Tag.WEREWOLF
@export var multiplier: float = 2.0
# A lone tenant is not a pack. The row needs at least this many rooms.
@export var min_pack_size: int = 2


func get_stage() -> Stage:
	return Stage.MULTIPLICATIVE


func apply(
	current_rent: int,
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int:
	# A room's row is the row it starts on.
	var row_rooms: Array[RoomInstance] = context.get_rooms_in_row(
		room_instance.grid_position.y
	)

	# Every room on the row must be a pack member, so the row's room count
	# is also the pack size.
	if row_rooms.size() < min_pack_size:
		return current_rent

	for row_room: RoomInstance in row_rooms:
		# Read through the context so previews include a hypothetical tenant.
		if not context.is_room_occupied(row_room):
			return current_rent

		var row_tenant: TenantInstance = context.get_tenant(row_room)

		if not row_tenant.tenant_resource.has_tag(tag):
			return current_rent

	return roundi(float(current_rent) * multiplier)
