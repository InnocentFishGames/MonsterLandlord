class_name SwapTenantsEffect
extends ActionEffect


# Used by: Swap (data/actions/swap.tres).
# The player picks two tenants in the building and they trade places.
# With fewer than two tenants there is nothing to swap, so it fizzles.


func execute(context: ActionContext) -> void:
	var occupied_positions: Array[Vector2i] = context.get_occupied_positions()

	if occupied_positions.size() < 2:
		return

	var first_position: Vector2i = await context.choose_cell(
		occupied_positions,
		"Swap: click the first tenant."
	)

	occupied_positions.erase(first_position)

	var second_position: Vector2i = await context.choose_cell(
		occupied_positions,
		"Swap: click the tenant to trade places with."
	)

	context.swap_tenants(first_position, second_position)


func can_resolve(context: ActionContext) -> bool:
	# Needs two tenants to trade places.
	return context.get_occupied_positions().size() >= 2
