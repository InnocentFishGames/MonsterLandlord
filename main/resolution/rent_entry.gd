class_name RentEntry
extends RefCounted


# One line of the resolution log: which room paid, who lives there,
# and how much rent that tenant produced after all effects.
var grid_position: Vector2i
var tenant_name: String
var rent: int
# How the rent was built, in order, e.g. "base $10", "Human neighbors → $20".
var steps: Array[String]


func _init(
	new_grid_position: Vector2i,
	new_tenant_name: String,
	new_rent: int,
	new_steps: Array[String]
) -> void:
	grid_position = new_grid_position
	tenant_name = new_tenant_name
	rent = new_rent
	steps = new_steps
