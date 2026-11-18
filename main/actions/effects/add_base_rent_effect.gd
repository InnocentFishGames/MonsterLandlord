class_name AddBaseRentEffect
extends ActionEffect


# Used by: Rent Hike (data/items/rent_hike.tres).
# The player picks a tenant in the building. Its base rent goes up for the
# rest of the run (see TenantInstance.base_rent_bonus).

@export var amount: int = 10


func execute(context: ActionContext) -> void:
	var occupied_positions: Array[Vector2i] = context.get_occupied_positions()

	if occupied_positions.is_empty():
		return

	var chosen_position: Vector2i = await context.choose_cell(
		occupied_positions,
		"Click a tenant to give +$%d base rent." % amount
	)

	context.add_base_rent(chosen_position, amount)


func can_resolve(context: ActionContext) -> bool:
	return not context.get_occupied_positions().is_empty()
