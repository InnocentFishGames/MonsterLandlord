class_name DistinctNeighborTypesRentAbility
extends TenantAbility


# Used by: Witch. Adds rent for each different tag found on the orthogonal
# neighbors. Two Undead neighbors count Undead once; a Vampire (Vampire +
# Undead) counts two tags.
@export var rent_per_type: int = 2


func execute(
	context: AbilityContext,
	source_tenant: TenantInstance,
	source_position: Vector2i
) -> void:
	var seen_tags: Array[TenantResource.Tag] = []

	for neighbor: TenantInstance in (
		context.building_state.get_neighbor_tenants(source_position)
	):
		for tag: TenantResource.Tag in neighbor.tenant_resource.tags:
			if not seen_tags.has(tag):
				seen_tags.append(tag)

	if seen_tags.is_empty():
		return

	context.add_rent(
		seen_tags.size() * rent_per_type,
		source_tenant,
		source_position,
		"%d neighbor types" % seen_tags.size()
	)
