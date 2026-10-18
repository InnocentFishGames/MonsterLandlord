class_name HumanNeighborRentEffect
extends RentEffect


@export var rent_per_human_neighbor: int = 5

func get_stage() -> Stage:
	# The Human neighbor bonus adds a flat amount to rent.

	return Stage.ADDITIVE
	
	
func apply(
	current_rent: int,
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int:
	var bonus_rent: int = 0

	var neighbors: Array[RoomInstance] = (
		context.get_neighbor_rooms(room_instance)
	)

	for neighbor_room: RoomInstance in neighbors:
		# Read occupancy through the context so previews include
		# the hypothetical tenant as well as real tenants.
		if not context.is_room_occupied(neighbor_room):
			continue

		var neighbor_tenant: TenantInstance = (
			context.get_tenant(neighbor_room)
		)

		if not neighbor_tenant.tenant_resource.has_tag(
			TenantResource.Tag.HUMAN
		):
			continue

		bonus_rent += rent_per_human_neighbor

	return current_rent + bonus_rent
