class_name AbilityContext
extends RefCounted


# Everything an ability is allowed to do while it runs. Game creates one per
# chain. Abilities never touch the interface or Game.

var building_state: BuildingState
var round_state: RoundState
# Bonuses the player owns, in the order they were bought.
var persistent_bonuses: Array[PersistentBonus] = []

# New events raised by abilities while they run. The ChainResolver collects
# them after each ability and queues them behind the existing events.
var _raised_events: Array[GameEvent] = []


func _init(
	new_building_state: BuildingState,
	new_round_state: RoundState,
	new_persistent_bonuses: Array[PersistentBonus] = []
) -> void:
	building_state = new_building_state
	round_state = new_round_state
	persistent_bonuses = new_persistent_bonuses


func add_rent(
	amount: int,
	source_tenant: TenantInstance,
	source_position: Vector2i,
	reason: String
) -> void:
	# Rent goes to the round's total, with a log line saying where it came from.
	var log_line: String = "%s at (%d, %d): %+d  %s" % [
		source_tenant.tenant_resource.tenant_name,
		source_position.x,
		source_position.y,
		amount,
		reason
	]

	round_state.add_rent(amount, log_line)


func raise_event(game_event: GameEvent) -> void:
	_raised_events.append(game_event)


func take_raised_events() -> Array[GameEvent]:
	var events: Array[GameEvent] = _raised_events.duplicate()
	_raised_events.clear()

	return events


func add_bonus_rent(
	amount: int,
	bonus: PersistentBonus,
	reason: String
) -> void:
	round_state.add_rent(
		amount,
		"Bonus %s: %+d  %s" % [bonus.bonus_name, amount, reason]
	)
