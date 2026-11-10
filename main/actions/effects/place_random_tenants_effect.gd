class_name PlaceRandomTenantsEffect
extends ActionEffect


# Used by: Random Arrivals (data/actions/random_arrivals.tres).
# Draws tenants and places each one in a random, different empty cell.
# If there are more tenants than empty cells, the extra tenants are
# discarded. Which ones get a cell is random, because the draw is random.

@export var tenant_count: int = 2


func execute(context: ActionContext) -> void:
	var drawn_tenants: Array[TenantInstance] = context.draw_tenants(
		tenant_count
	)

	var empty_positions: Array[Vector2i] = context.get_empty_positions()
	empty_positions.shuffle()

	# All arrivals are placed before anything reacts to them, so tenants
	# that arrive together can see each other.
	for tenant_instance: TenantInstance in drawn_tenants:
		if empty_positions.is_empty():
			context.discard_tenants([tenant_instance])
			continue

		context.place_tenant(
			empty_positions.pop_back(),
			tenant_instance,
			GameEvent.Trigger.RANDOM_PLACEMENT
		)


func can_resolve(context: ActionContext) -> bool:
	return (
		context.tenant_bag.get_bag_size() > 0
		and not context.get_empty_positions().is_empty()
	)
