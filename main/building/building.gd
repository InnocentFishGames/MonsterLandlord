class_name Building
extends Node2D


@export var grid_component: GridComponent
@export var room_container: RoomManager


func initialize() -> bool:
	# Building validates the component references assigned to it.
	if grid_component == null:
		push_error(
			"Building: GridComponent has not been assigned."
		)
		return false

	if room_container == null:
		push_error(
			"Building: RoomManager has not been assigned."
		)
		return false

	# Validate the grid before any room-placement calculations.
	if not grid_component.initialize():
		return false

	# RoomManager validates its own dependencies.
	if not room_container.initialize():
		return false

	return true
