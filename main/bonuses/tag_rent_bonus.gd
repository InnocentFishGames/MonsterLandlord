class_name TagRentBonus
extends PersistentBonus


# Used by: Crypt Fee (data/bonuses/crypt_fee.tres).
# Pays rent for every tenant in the building that has the tag.
@export var tag: TenantResource.Tag = TenantResource.Tag.UNDEAD
@export var amount_each: int = 4


func execute(context: AbilityContext) -> void:
	var matching_tenants: int = 0

	for grid_position: Vector2i in context.building_state.get_occupied_positions():
		var tenant: TenantInstance = context.building_state.get_tenant_at(
			grid_position
		)

		if tenant.tenant_resource.has_tag(tag):
			matching_tenants += 1

	if matching_tenants == 0:
		return

	context.add_bonus_rent(
		matching_tenants * amount_each,
		self,
		"%d %s tenants" % [
			matching_tenants, TenantResource.Tag.keys()[tag].capitalize()
		]
	)
