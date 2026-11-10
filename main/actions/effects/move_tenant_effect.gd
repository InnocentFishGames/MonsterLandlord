class_name MoveTenantEffect
extends ActionEffect


# Used by: Move (data/actions/move.tres).
# The player picks a tenant in the building, then any empty cell. The tenant
# moves there. Needs a tenant and at least one empty cell.


func execute(context: ActionContext) -> void:
	var occupied_positions: Array[Vector2i] = context.get_occupied_positions()

	if occupied_positions.is_empty() or context.get_empty_positions().is_empty():
		return

	var from_position: Vector2i = await context.choose_cell(
		occupied_positions,
		"Move: click the tenant to move."
	)

	var to_position: Vector2i = await context.choose_cell(
		context.get_empty_positions(),
		"Move: click an empty cell."
	)

	context.move_tenant(from_position, to_position)


func can_resolve(context: ActionContext) -> bool:
	return (
		not context.get_occupied_positions().is_empty()
		and not context.get_empty_positions().is_empty()
	)
