class_name FlatRentAbility
extends TenantAbility


# Used by: every tenant (their base rent).
@export var amount: int = 10


func execute(
	context: AbilityContext,
	source_tenant: TenantInstance,
	source_position: Vector2i
) -> void:
	context.add_rent(amount, source_tenant, source_position, "Base rent")
