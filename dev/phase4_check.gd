extends Node

# TEMPORARY scripted check of events, the chain, and the five tenants' rent.
# Run: dev/phase4_check.tscn (F6).


# Test-only ability: hears ANY chosen placement and raises another one.
# Without loop prevention this would never stop.
class LoopAbility:
	extends TenantAbility

	func execute(
		context: AbilityContext,
		source_tenant: TenantInstance,
		source_position: Vector2i
	) -> void:
		context.add_rent(1, source_tenant, source_position, "loop test")
		context.raise_event(
			GameEvent.new(GameEvent.Trigger.CHOSEN_PLACEMENT)
		)


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _tenant(file_name: String) -> TenantInstance:
	var tenant_resource: TenantResource = load(
		"res://main/data/tenants/%s.tres" % file_name
	)
	return TenantInstance.new(tenant_resource)


func _board() -> Array:
	# Returns [BuildingState, RoundState, AbilityContext].
	var building_state: BuildingState = BuildingState.new()
	building_state.setup(4, 4)
	var round_state: RoundState = RoundState.new()
	round_state.start_round(6)
	return [
		building_state,
		round_state,
		AbilityContext.new(building_state, round_state)
	]


func _round_end(context: AbilityContext) -> int:
	return ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.ROUND_END)], context
	)


func _ready() -> void:
	# --- Human: flat rent ---
	var parts: Array = _board()
	var building_state: BuildingState = parts[0]
	var round_state: RoundState = parts[1]
	var context: AbilityContext = parts[2]
	building_state.place_tenant(Vector2i(0, 0), _tenant("human"))
	_round_end(context)
	_report(round_state.rent_total == 10, "lone Human pays 10")
	_report(round_state.rent_log.size() == 1, "one rent log line")

	# --- Vampire: 10 + 5 per adjacent Human (Human also pays 10) ---
	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	building_state.place_tenant(Vector2i(1, 1), _tenant("vampire"))
	building_state.place_tenant(Vector2i(0, 1), _tenant("human"))
	building_state.place_tenant(Vector2i(2, 1), _tenant("human"))
	building_state.place_tenant(Vector2i(2, 2), _tenant("human"))  # diagonal
	_round_end(context)
	# Vampire 10 + 2*5 = 20, three Humans 30.
	_report(round_state.rent_total == 50, "Vampire counts 2 orthogonal Humans only")

	# --- Witch: 5 + 2 per distinct neighbor tag ---
	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	building_state.place_tenant(Vector2i(1, 1), _tenant("witch"))
	building_state.place_tenant(Vector2i(0, 1), _tenant("vampire"))  # VAMPIRE, UNDEAD
	building_state.place_tenant(Vector2i(2, 1), _tenant("zombie"))  # ZOMBIE, UNDEAD
	_round_end(context)
	# Witch: 5 + 2 * {VAMPIRE, UNDEAD, ZOMBIE} = 11. Vampire 10. Zombie 2.
	_report(round_state.rent_total == 11 + 10 + 2, "Witch counts distinct neighbor tags once")

	# --- Zombie: doubles per earlier zombie, in top-left to bottom-right order ---
	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	building_state.place_tenant(Vector2i(3, 3), _tenant("zombie"))
	building_state.place_tenant(Vector2i(0, 0), _tenant("zombie"))
	building_state.place_tenant(Vector2i(2, 1), _tenant("zombie"))
	_round_end(context)
	# Order: (0,0)=2, (2,1)=4, (3,3)=8.
	_report(round_state.rent_total == 14, "Zombies double per earlier Zombie (2+4+8)")
	_report(
		round_state.rent_log[0].begins_with("Zombie at (0, 0)")
		and round_state.rent_log[2].begins_with("Zombie at (3, 3)"),
		"rent resolves top-left to bottom-right"
	)

	# --- Werewolf pack ---
	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	building_state.place_tenant(Vector2i(0, 2), _tenant("werewolf"))
	building_state.place_tenant(Vector2i(3, 2), _tenant("werewolf"))
	_round_end(context)
	_report(round_state.rent_total == 40, "two Werewolves alone in a row form a pack (20 each)")

	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	building_state.place_tenant(Vector2i(0, 2), _tenant("werewolf"))
	building_state.place_tenant(Vector2i(1, 2), _tenant("human"))
	_round_end(context)
	_report(round_state.rent_total == 20, "a Human in the row breaks the pack")

	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	building_state.place_tenant(Vector2i(0, 2), _tenant("werewolf"))
	_round_end(context)
	_report(round_state.rent_total == 10, "a lone Werewolf is not a pack")

	# --- Chain rules ---
	parts = _board()
	building_state = parts[0]
	round_state = parts[1]
	context = parts[2]
	var loop_ability: LoopAbility = LoopAbility.new()
	loop_ability.trigger = GameEvent.Trigger.CHOSEN_PLACEMENT
	loop_ability.reacts_to_other_tenants = true
	var loop_resource: TenantResource = TenantResource.new()
	loop_resource.tenant_name = "Looper"
	loop_resource.abilities = [loop_ability]
	building_state.place_tenant(Vector2i(0, 0), TenantInstance.new(loop_resource))
	building_state.place_tenant(Vector2i(1, 0), TenantInstance.new(loop_resource))
	var ran: int = ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.CHOSEN_PLACEMENT)], context
	)
	# Two tenants share one ability resource but are different sources.
	_report(ran == 2 and round_state.rent_total == 2, "looping abilities each run once per chain")

	var other_trigger_ran: int = ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.RANDOM_PLACEMENT)], context
	)
	_report(other_trigger_ran == 0, "abilities ignore other triggers")

	# --- Through the real game: Random Arrivals then End Round ---
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame

	var random_card: ActionResource = load("res://main/data/actions/random_arrivals.tres")
	game.action_deck.setup([random_card, random_card, random_card, random_card, random_card])
	game.action_deck.start_round(5)
	game.hud.action_card_selected.emit(random_card)

	var placed: int = game.building.building_state.tenants_by_position.size()
	_report(placed == 2, "Random Arrivals placed 2 tenants")
	_report(game.round_state.rent_total == 0, "no rent before the round ends")

	_report(not game.hud.projected_rent_label.text.begins_with("Projected rent: $0 "), "projected rent shown after placements")
	var projected: String = game.hud.projected_rent_label.text

	game.hud.end_round_requested.emit()
	_report(game.round_state.rent_total > 0, "End Round pays rent from abilities")
	_report(projected.begins_with("Projected rent: $%d " % game.round_state.rent_total), "projection matches the real payout")
	_report(
		game.hud.rent_label.text == "Rent: $%d" % game.round_state.rent_total,
		"HUD shows the rent total"
	)
	_report(
		game.hud.rent_log_label.text.count("\n") + 1 >= placed,
		"HUD shows the rent log"
	)

	game._start_round()
	_report(game.round_state.rent_total == 0, "next round resets rent")

	print("--- phase 4 check finished ---")
	get_tree().quit()
