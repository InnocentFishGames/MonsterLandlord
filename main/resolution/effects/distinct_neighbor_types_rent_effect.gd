class_name DistinctNeighborTypesRentEffect
extends RentEffect


# Used by: Banquet Hall (data/rooms/banquet_hall.tres) and Witch
# (data/tenants/witch.tres).
# Adds rent for each different tag found on the tenants in orthogonal
# neighbor rooms. Two Undead neighbors count Undead once. A Vampire
# (Vampire + Undead) counts two tags.

@export var rent_per_type: int = 2


func get_stage() -> Stage:
	return Stage.ADDITIVE


func apply(
	current_rent: int,
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int:
	var seen_tags: Array[TenantResource.Tag] = []

	for neighbor_room: RoomInstance in context.get_neighbor_rooms(
		room_instance
	):
		# Read through the context so previews include hypothetical tenants.
		if not context.is_room_occupied(neighbor_room):
			continue

		var neighbor_tenant: TenantInstance = (
			context.get_tenant(neighbor_room)
		)

		for tag: TenantResource.Tag in neighbor_tenant.tenant_resource.tags:
			if not seen_tags.has(tag):
				seen_tags.append(tag)

	return current_rent + seen_tags.size() * rent_per_type
