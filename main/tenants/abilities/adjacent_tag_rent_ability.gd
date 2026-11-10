class_name AdjacentTagRentAbility
extends TenantAbility


# Used by: Vampire. Adds rent for every orthogonal neighbor with the tag.
@export var tag: TenantResource.Tag = TenantResource.Tag.HUMAN
@export var rent_per_neighbor: int = 5


func execute(
	context: AbilityContext,
	source_tenant: TenantInstance,
	source_position: Vector2i
) -> void:
	var matching_neighbors: int = 0

	for neighbor: TenantInstance in (
		context.building_state.get_neighbor_tenants(source_position)
	):
		if neighbor.tenant_resource.has_tag(tag):
			matching_neighbors += 1

	if matching_neighbors == 0:
		return

	context.add_rent(
		matching_neighbors * rent_per_neighbor,
		source_tenant,
		source_position,
		"%d neighboring %s"
		% [matching_neighbors, TenantResource.Tag.keys()[tag].capitalize()]
	)
