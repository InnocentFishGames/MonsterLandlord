class_name BuildingState
extends RefCounted


# Announce every change to the board, so views can redraw and (later)
# abilities can react. Nothing outside this class changes the board.
signal tenant_placed(grid_position: Vector2i, tenant_instance: TenantInstance)
signal tenant_removed(grid_position: Vector2i, tenant_instance: TenantInstance)
# A cell changed without a placement or removal (swap, move, transform).
# The tenant is null when the cell is now empty.
signal tenant_changed(grid_position: Vector2i, tenant_instance: TenantInstance)
signal cleared()


# Which tenant stands on which grid cell. This is the ONLY place that knows
# who is where. Visuals (the grid drawing, tenant sprites, the purely
# decorative background) read from here and never store their own copy.
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
	tenant_placed.emit(grid_position, tenant_instance)

	return true


func remove_tenant(grid_position: Vector2i) -> TenantInstance:
	# Returns the removed tenant, or null if the cell was already empty.
	var removed_tenant: TenantInstance = get_tenant_at(grid_position)

	if removed_tenant == null:
		return null

	tenants_by_position.erase(grid_position)
	tenant_removed.emit(grid_position, removed_tenant)

	return removed_tenant


func clear() -> void:
	# Round cleanup. TenantBag.return_all_to_bag() is what gives the tenants
	# back to the player, so nothing is lost here.
	tenants_by_position.clear()
	cleared.emit()


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


func get_neighbor_tenants(grid_position: Vector2i) -> Array[TenantInstance]:
	# Only the four orthogonal neighbors count. Empty cells are skipped.
	var neighbors: Array[TenantInstance] = []

	for offset: Vector2i in [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
	]:
		var neighbor: TenantInstance = get_tenant_at(grid_position + offset)

		if neighbor != null:
			neighbors.append(neighbor)

	return neighbors


func get_tenants_in_row(row: int) -> Array[TenantInstance]:
	# Occupied cells of one row, left to right.
	var row_tenants: Array[TenantInstance] = []

	for column: int in range(columns):
		var tenant: TenantInstance = get_tenant_at(Vector2i(column, row))

		if tenant != null:
			row_tenants.append(tenant)

	return row_tenants


func get_occupied_positions() -> Array[Vector2i]:
	var occupied_positions: Array[Vector2i] = []

	for grid_position: Vector2i in get_positions_in_order():
		if not is_empty(grid_position):
			occupied_positions.append(grid_position)

	return occupied_positions


func swap_tenants(first_position: Vector2i, second_position: Vector2i) -> bool:
	# Both cells must hold a tenant. Otherwise nothing happens (normal
	# gameplay, so no error).
	var first_tenant: TenantInstance = get_tenant_at(first_position)
	var second_tenant: TenantInstance = get_tenant_at(second_position)

	if (
		first_tenant == null
		or second_tenant == null
		or first_position == second_position
	):
		return false

	tenants_by_position[first_position] = second_tenant
	tenants_by_position[second_position] = first_tenant
	tenant_changed.emit(first_position, second_tenant)
	tenant_changed.emit(second_position, first_tenant)

	return true


func transform_tenant(
	grid_position: Vector2i,
	new_tenant_resource: TenantResource
) -> bool:
	var tenant_instance: TenantInstance = get_tenant_at(grid_position)

	if tenant_instance == null:
		return false

	if new_tenant_resource == null:
		push_error("BuildingState: Cannot transform into a null TenantResource.")
		return false

	tenant_instance.transform_to(new_tenant_resource)
	tenant_changed.emit(grid_position, tenant_instance)

	return true


func move_tenant(from_position: Vector2i, to_position: Vector2i) -> bool:
	# The tenant must exist and the target cell must be free. Otherwise
	# nothing happens (normal gameplay).
	var tenant_instance: TenantInstance = get_tenant_at(from_position)

	if (
		tenant_instance == null
		or not is_valid_position(to_position)
		or not is_empty(to_position)
	):
		return false

	tenants_by_position.erase(from_position)
	tenants_by_position[to_position] = tenant_instance
	tenant_changed.emit(from_position, null)
	tenant_changed.emit(to_position, tenant_instance)

	return true
