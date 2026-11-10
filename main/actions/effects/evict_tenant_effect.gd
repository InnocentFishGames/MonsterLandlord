class_name EvictTenantEffect
extends ActionEffect


# Used by: Evict (data/actions/evict.tres).
# The player picks a tenant in the building. It leaves and goes to the
# tenant discard pile until the round ends. Fizzles if the building is empty.


func execute(context: ActionContext) -> void:
	var occupied_positions: Array[Vector2i] = context.get_occupied_positions()

	if occupied_positions.is_empty():
		return

	var chosen_position: Vector2i = await context.choose_cell(
		occupied_positions,
		"Evict: click the tenant to remove."
	)

	context.remove_tenant(chosen_position)


func can_resolve(context: ActionContext) -> bool:
	return not context.get_occupied_positions().is_empty()
