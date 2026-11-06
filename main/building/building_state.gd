class_name BuildingState
extends RefCounted


# Which tenant stands on which grid cell. This is the ONLY place that knows
# who is where. Visuals (the grid drawing, tenant sprites, the purely
# decorative rooms) read from here and never store their own copy.
#
# Every tenant takes exactly one cell.

var columns: int = 0
var rows: int = 0

# Only occupied cells appear in this dictionary.
var tenants_by_position: Dictionary[Vector2i, TenantInstance] = {}


func setup(new_columns: int, new_rows: int) -> bool:
	if new_columns <= 0 or new_rows <= 0:
		push_error(
			"BuildingState: Columns and rows must be greater than zero."
		)
		return false

	columns = new_columns
	rows = new_rows
	tenants_by_position.clear()

	return true


func is_valid_position(grid_position: Vector2i) -> bool:
	return Rect2i(0, 0, columns, rows).has_point(grid_position)


func is_empty(grid_position: Vector2i) -> bool:
	return not tenants_by_position.has(grid_position)


func get_tenant_at(grid_position: Vector2i) -> TenantInstance:
	# Returns null for an empty cell.
	return tenants_by_position.get(grid_position)


func place_tenant(
	grid_position: Vector2i,
	tenant_instance: TenantInstance
) -> bool:
	if tenant_instance == null:
		push_error("BuildingState: Cannot place a null TenantInstance.")
		return false

	if not is_valid_position(grid_position):
		push_error(
			"BuildingState: Position %s is outside the %dx%d building."
			% [grid_position, columns, rows]
		)
		return false

	# An occupied cell is normal gameplay, so reject quietly.
	if not is_empty(grid_position):
		return false

	tenants_by_position[grid_position] = tenant_instance

	return true


func remove_tenant(grid_position: Vector2i) -> TenantInstance:
	# Returns the removed tenant, or null if the cell was already empty.
	var removed_tenant: TenantInstance = get_tenant_at(grid_position)
	tenants_by_position.erase(grid_position)

	return removed_tenant


func clear() -> void:
	# Round cleanup. TenantBag.return_all_to_bag() is what gives the tenants
	# back to the player, so nothing is lost here.
	tenants_by_position.clear()


func get_positions_in_order() -> Array[Vector2i]:
	# Top-left to bottom-right: left to right across the top row, then the
	# next row down. Abilities triggered by the same event use this order.
	var positions: Array[Vector2i] = []

	for row: int in range(rows):
		for column: int in range(columns):
			positions.append(Vector2i(column, row))

	return positions


func get_empty_positions() -> Array[Vector2i]:
	var empty_positions: Array[Vector2i] = []

	for grid_position: Vector2i in get_positions_in_order():
		if is_empty(grid_position):
			empty_positions.append(grid_position)

	return empty_positions
