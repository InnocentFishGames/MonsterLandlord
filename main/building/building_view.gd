class_name BuildingView
extends Node2D


# Draws the tenants standing in the building and lets the player click an
# empty cell when an action asks for one. It only READS BuildingState; the
# board itself is never changed here.

# The player clicked one of the highlighted cells.
signal cell_chosen(grid_position: Vector2i)


@export var grid_component: GridComponent

var building_state: BuildingState = null

# Cells the player may click right now. Empty when no choice is open.
var selectable_positions: Array[Vector2i] = []
var hovered_position: Vector2i = Vector2i(-1, -1)


func setup(new_building_state: BuildingState) -> bool:
	if grid_component == null:
		push_error(
			"BuildingView: GridComponent has not been assigned."
		)
		return false

	if new_building_state == null:
		push_error(
			"BuildingView: Cannot setup without a BuildingState."
		)
		return false

	building_state = new_building_state

	# Redraw whenever the board changes.
	building_state.tenant_placed.connect(_on_board_changed)
	building_state.tenant_removed.connect(_on_board_changed)
	building_state.tenant_changed.connect(_on_board_changed)
	building_state.cleared.connect(_on_cleared)

	# Input is only needed while the player is choosing a cell.
	set_process_unhandled_input(false)
	queue_redraw()

	return true


func begin_cell_choice(valid_positions: Array[Vector2i]) -> void:
	selectable_positions = valid_positions.duplicate()
	hovered_position = Vector2i(-1, -1)
	set_process_unhandled_input(true)
	queue_redraw()


func end_cell_choice() -> void:
	selectable_positions.clear()
	hovered_position = Vector2i(-1, -1)
	set_process_unhandled_input(false)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var new_hover: Vector2i = grid_component.world_to_grid_position(
			grid_component.get_local_mouse_position()
		)

		if new_hover != hovered_position:
			hovered_position = new_hover
			queue_redraw()

		return

	if event is not InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton

	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return

	var clicked_position: Vector2i = grid_component.world_to_grid_position(
		grid_component.get_local_mouse_position()
	)

	# Clicking anywhere else does nothing; the player keeps choosing.
	if not selectable_positions.has(clicked_position):
		return

	# Close the choice first so a second click cannot answer it twice.
	end_cell_choice()
	cell_chosen.emit(clicked_position)


func _on_board_changed(
	_grid_position: Vector2i,
	_tenant_instance: TenantInstance
) -> void:
	queue_redraw()


func _on_cleared() -> void:
	queue_redraw()


func _draw() -> void:
	if building_state == null:
		return

	var cell_size: Vector2 = grid_component.grid_size

	# Highlight the cells the player can choose.
	for grid_position: Vector2i in selectable_positions:
		var highlight_color: Color = Color(0.2, 1.0, 0.2, 0.25)

		if grid_position == hovered_position:
			highlight_color = Color(0.2, 1.0, 0.2, 0.55)

		draw_rect(
			Rect2(grid_component.grid_to_world_position(grid_position), cell_size),
			highlight_color
		)

	# Placeholder tenant art: a circle with the name underneath.
	var font: Font = ThemeDB.fallback_font

	for grid_position: Vector2i in building_state.tenants_by_position:
		var tenant_instance: TenantInstance = (
			building_state.tenants_by_position[grid_position]
		)
		var cell_origin: Vector2 = grid_component.grid_to_world_position(
			grid_position
		)

		draw_circle(cell_origin + cell_size * 0.5, 50.0, Color.WHITE)

		draw_string(
			font,
			cell_origin + Vector2(0.0, cell_size.y * 0.5 + 85.0),
			_get_label_text(tenant_instance),
			HORIZONTAL_ALIGNMENT_CENTER,
			cell_size.x,
			26,
			Color.WHITE
		)


func _get_label_text(tenant_instance: TenantInstance) -> String:
	# Shows the extra base rent an item gave this tenant, e.g. "Human (+$10)".
	if tenant_instance.base_rent_bonus == 0:
		return tenant_instance.tenant_resource.tenant_name

	return "%s (+$%d)" % [
		tenant_instance.tenant_resource.tenant_name,
		tenant_instance.base_rent_bonus
	]
