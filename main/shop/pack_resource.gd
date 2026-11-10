class_name PackResource
extends Resource


# A pack sold in the shop. Buying it shows `choices_shown` random items from
# its list and the player keeps one. Fill EITHER tenants OR actions.
# Read-only during play.

@export var pack_name: String = ""
@export_multiline var description: String = ""
@export var tenants: Array[TenantResource] = []
@export var actions: Array[ActionResource] = []
@export var choices_shown: int = 3
@export var shop_price: int = 5


func is_tenant_pack() -> bool:
	return not tenants.is_empty()


func validate() -> bool:
	if tenants.is_empty() == actions.is_empty():
		push_error(
			"PackResource '%s': Fill either Tenants or Actions, not both and not neither."
			% pack_name
		)
		return false

	if choices_shown <= 0:
		push_error(
			"PackResource '%s': Choices Shown must be greater than zero."
			% pack_name
		)
		return false

	for tenant_resource: TenantResource in tenants:
		if tenant_resource == null:
			push_error("PackResource '%s': Tenants has an empty slot." % pack_name)
			return false

	for action_resource: ActionResource in actions:
		if action_resource == null:
			push_error("PackResource '%s': Actions has an empty slot." % pack_name)
			return false

	return true
