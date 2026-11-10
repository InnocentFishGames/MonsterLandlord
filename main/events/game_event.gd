class_name GameEvent
extends RefCounted


# Something that happened on the board. Abilities react to events.
# Events are small facts: they describe what happened, not what to do.

# How the tenant arrived matters: some abilities only care about chosen
# placements, others only about random ones.
enum Trigger {
	CHOSEN_PLACEMENT,
	RANDOM_PLACEMENT,
	SWAP,
	TRANSFORMATION,
	REMOVAL,
	ACTION_PLAYED,
	ROUND_END
}

var trigger: Trigger
# The tenant the event is about. Null for events that belong to nobody,
# such as ROUND_END and ACTION_PLAYED.
var tenant: TenantInstance
var grid_position: Vector2i


func _init(
	new_trigger: Trigger,
	new_tenant: TenantInstance = null,
	new_grid_position: Vector2i = Vector2i.ZERO
) -> void:
	trigger = new_trigger
	tenant = new_tenant
	grid_position = new_grid_position
