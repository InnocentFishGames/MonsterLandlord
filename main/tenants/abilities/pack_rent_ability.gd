class_name PackRentAbility
extends TenantAbility


# Used by: Werewolf ("Pack"). If every tenant in this row has the tag (and
# there are at least min_pack_size of them), adds bonus_amount. The Werewolf's
# only other rent is its base rent, so a bonus equal to the base rent is the
# old "doubles its rent". Empty cells are ignored.
@export var tag: TenantResource.Tag = TenantResource.Tag.WEREWOLF
@export var bonus_amount: int = 10
@export var min_pack_size: int = 2


func execute(
	context: AbilityContext,
	source_tenant: TenantInstance,
	source_position: Vector2i
) -> void:
	var row_tenants: Array[TenantInstance] = (
		context.building_state.get_tenants_in_row(source_position.y)
	)

	if row_tenants.size() < min_pack_size:
		return

	for row_tenant: TenantInstance in row_tenants:
		if not row_tenant.tenant_resource.has_tag(tag):
			return

	context.add_rent(
		bonus_amount, source_tenant, source_position, "Pack bonus"
	)
