class_name Building
extends Node2D


@export var grid_component: GridComponent
@export var building_view: BuildingView

# Who stands where. Created in initialize() from the grid's size.
# Visuals read from this and never keep their own copy.
var building_state: BuildingState = null


func initialize() -> bool:
	# Building validates the component references assigned to it.
	if grid_component == null:
		push_error(
			"Building: GridComponent has not been assigned."
		)
		return false

	if building_view == null:
		push_error(
			"Building: BuildingView has not been assigned."
		)
		return false

	# Validate the grid before using its size.
	if not grid_component.initialize():
		return false

	# The grid's columns and rows (set in the Inspector) decide the size.
	building_state = BuildingState.new()

	if not building_state.setup(
		grid_component.columns,
		grid_component.rows
	):
		return false

	# The view validates its own dependencies.
	return building_view.setup(building_state)
