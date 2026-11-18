class_name EarlierTagRentAbility
extends TenantAbility


# Used by: Zombie. Pays base_amount, multiplied for every tenant with the tag
# that comes earlier in top-left to bottom-right order. With base 2 and
# multiplier 2: the first Zombie earns 2, the next 4, then 8.
@export var tag: TenantResource.Tag = TenantResource.Tag.ZOMBIE
@export var base_amount: int = 2
@export var multiplier: float = 2.0


func execute(
	context: AbilityContext,
	source_tenant: TenantInstance,
	source_position: Vector2i
) -> void:
	var earlier_count: int = 0

	for grid_position: Vector2i in (
		context.building_state.get_positions_in_order()
	):
		if grid_position == source_position:
			break

		var earlier_tenant: TenantInstance = (
			context.building_state.get_tenant_at(grid_position)
		)

		if (
			earlier_tenant != null
			and earlier_tenant.tenant_resource.has_tag(tag)
		):
			earlier_count += 1

	context.add_rent(
		roundi(
			float(base_amount + source_tenant.base_rent_bonus)
			* pow(multiplier, earlier_count)
		),
		source_tenant,
		source_position,
		"%d earlier %s" % [
			earlier_count,
			TenantResource.Tag.keys()[tag].capitalize()
		]
	)
