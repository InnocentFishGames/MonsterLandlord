class_name TradeWithBagEffect
extends ActionEffect


# Used by: Trade (data/actions/trade.tres).
# The player picks a tenant in the building. It goes back into the bag and
# a random tenant from the bag takes its cell.
#
# The replacement is drawn BEFORE the old tenant goes back, so the tenant you
# just sent away can never be the one that comes back. Another tenant of the
# same type is fine.
# Fizzles (nothing is drawn or moved) if the building is empty or the bag is empty.


func execute(context: ActionContext) -> void:
	var occupied_positions: Array[Vector2i] = context.get_occupied_positions()

	if occupied_positions.is_empty():
		return

	var drawn_tenants: Array[TenantInstance] = context.draw_tenants(1)

	if drawn_tenants.is_empty():
		return

	var replacement: TenantInstance = drawn_tenants[0]

	var target_position: Vector2i = await context.choose_cell(
		occupied_positions,
		"Trade: click the tenant to send back. %s takes its place."
		% replacement.tenant_resource.tenant_name
	)

	context.send_tenant_back_to_bag(target_position)
	context.place_tenant(
		target_position,
		replacement,
		GameEvent.Trigger.RANDOM_PLACEMENT
	)


func can_resolve(context: ActionContext) -> bool:
	# Needs a tenant on the board to send back and a tenant in the bag to
	# take its place.
	return (
		not context.get_occupied_positions().is_empty()
		and context.tenant_bag.get_bag_size() > 0
	)
