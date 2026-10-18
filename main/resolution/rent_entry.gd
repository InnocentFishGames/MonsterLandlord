class_name RentEntry
extends RefCounted


# One line of the resolution log: which room paid, who lives there,
# and how much rent that tenant produced after all effects.
var grid_position: Vector2i
var tenant_name: String
var rent: int


func _init(
	new_grid_position: Vector2i,
	new_tenant_name: String,
	new_rent: int
) -> void:
	grid_position = new_grid_position
	tenant_name = new_tenant_name
	rent = new_rent
