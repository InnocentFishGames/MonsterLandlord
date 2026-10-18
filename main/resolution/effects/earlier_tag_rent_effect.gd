class_name EarlierTagRentEffect
extends RentEffect


# Used by: Zombie (data/tenants/zombie.tres).
# Multiplies rent for every tenant with the chosen tag that resolves
# earlier in the resolution order. With a multiplier of 2 and a base rent of
# 2, the first Zombie earns 2, the next 4, then 8, and so on.
# Replays (Echo Room) do not count, only the rooms' positions.

@export var tag: TenantResource.Tag = TenantResource.Tag.ZOMBIE
@export var multiplier: float = 2.0


func get_stage() -> Stage:
	return Stage.MULTIPLICATIVE


func apply(
	current_rent: int,
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int:
	var earlier_count: int = 0

	for earlier_room: RoomInstance in context.get_rooms_before(
		room_instance
	):
		var earlier_tenant: TenantInstance = (
			context.get_tenant(earlier_room)
		)

		if earlier_tenant.tenant_resource.has_tag(tag):
			earlier_count += 1

	return roundi(
		float(current_rent) * pow(multiplier, earlier_count)
	)
