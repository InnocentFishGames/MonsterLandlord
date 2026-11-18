extends Node

# TEMPORARY scripted check of swap, remove and transform.
# Run: dev/phase5_check.tscn (F6).


# Test-only ability: pays 1 whenever ITS OWN tenant is swapped.
class SwapPaysAbility:
	extends TenantAbility

	func execute(
		context: AbilityContext,
		source_tenant: TenantInstance,
		source_position: Vector2i
	) -> void:
		context.add_rent(1, source_tenant, source_position, "swap test")


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _res(file_name: String) -> TenantResource:
	return load("res://main/data/tenants/%s.tres" % file_name)


func _make_context() -> ActionContext:
	var tenant_bag: TenantBag = TenantBag.new()
	tenant_bag.setup([
		_res("human"), _res("vampire"), _res("witch"), _res("zombie")
	])
	var building_state: BuildingState = BuildingState.new()
	building_state.setup(4, 4)
	return ActionContext.new(tenant_bag, building_state, RunState.new())


func _answer_cells(context: ActionContext, answers: Array[Vector2i]) -> void:
	var queue: Array[Vector2i] = answers.duplicate()
	context.cell_choice_requested.connect(
		func(_valid: Array[Vector2i], _prompt: String) -> void:
			context.submit_cell_choice.call_deferred(queue.pop_front())
	)


func _ready() -> void:
	# --- Swap ---
	var context: ActionContext = _make_context()
	var human: TenantInstance = context.tenant_bag.roster[0]
	var vampire: TenantInstance = context.tenant_bag.roster[1]
	context.building_state.place_tenant(Vector2i(0, 0), human)
	context.building_state.place_tenant(Vector2i(3, 3), vampire)
	_answer_cells(context, [Vector2i(0, 0), Vector2i(3, 3)])
	await SwapTenantsEffect.new().execute(context)
	_report(
		context.building_state.get_tenant_at(Vector2i(0, 0)) == vampire
		and context.building_state.get_tenant_at(Vector2i(3, 3)) == human,
		"swap: tenants traded places"
	)
	_report(
		context.events.size() == 2
		and context.events[0].trigger == GameEvent.Trigger.SWAP
		and context.events[0].tenant == vampire
		and context.events[0].grid_position == Vector2i(0, 0),
		"swap: one SWAP event per tenant at its new cell"
	)

	context = _make_context()
	context.building_state.place_tenant(Vector2i(1, 1), context.tenant_bag.roster[0])
	await SwapTenantsEffect.new().execute(context)
	_report(context.events.is_empty(), "swap: fizzles with fewer than 2 tenants")
	_report(not context.building_state.swap_tenants(Vector2i(1, 1), Vector2i(2, 2)), "swap with an empty cell is rejected")

	# An ability reacting to SWAP runs after the card via the chain.
	context = _make_context()
	var swap_ability: SwapPaysAbility = SwapPaysAbility.new()
	swap_ability.trigger = GameEvent.Trigger.SWAP
	var pays_resource: TenantResource = TenantResource.new()
	pays_resource.tenant_name = "SwapPayer"
	pays_resource.abilities = [swap_ability]
	context.building_state.place_tenant(Vector2i(0, 0), TenantInstance.new(pays_resource))
	context.building_state.place_tenant(Vector2i(1, 0), context.tenant_bag.roster[0])
	_answer_cells(context, [Vector2i(0, 0), Vector2i(1, 0)])
	await SwapTenantsEffect.new().execute(context)
	var round_state: RoundState = RoundState.new()
	round_state.start_round(6)
	ChainResolver.new().resolve(
		context.events, AbilityContext.new(context.building_state, round_state)
	)
	_report(round_state.rent_total == 1, "SWAP ability ran once, only for its own tenant")

	# --- Remove ---
	context = _make_context()
	human = context.tenant_bag.roster[0]
	context.tenant_bag.bag.erase(human)
	context.building_state.place_tenant(Vector2i(2, 1), human)
	_answer_cells(context, [Vector2i(2, 1)])
	await EvictTenantEffect.new().execute(context)
	_report(context.building_state.is_empty(Vector2i(2, 1)), "remove: cell is empty")
	_report(context.tenant_bag.discard_pile.has(human), "remove: tenant went to the discard pile")
	_report(
		context.events.size() == 1
		and context.events[0].trigger == GameEvent.Trigger.REMOVAL
		and context.events[0].tenant == human,
		"remove: REMOVAL event recorded"
	)
	context = _make_context()
	await EvictTenantEffect.new().execute(context)
	_report(context.events.is_empty(), "remove: empty building fizzles")

	# --- Transformation (engine only; no card uses it right now) ---
	context = _make_context()
	human = context.tenant_bag.roster[0]
	context.building_state.place_tenant(Vector2i(0, 0), human)
	context.transform_tenant(Vector2i(0, 0), _res("witch"))
	_report(human.tenant_resource == _res("witch"), "transform: became a Witch")
	_report(human.base_resource == _res("human"), "transform: original type remembered")
	_report(
		context.events.size() == 1
		and context.events[0].trigger == GameEvent.Trigger.TRANSFORMATION,
		"transform: TRANSFORMATION event recorded"
	)
	context.tenant_bag.return_all_to_bag()
	_report(human.tenant_resource == _res("human"), "transform: undone when tenants return to the bag")

	# --- Swap with the bag ---
	context = _make_context()
	var bag_human: TenantInstance = context.tenant_bag.roster[0]
	var bag_zombie: TenantInstance = context.tenant_bag.roster[3]
	context.tenant_bag.bag.erase(bag_human)
	context.building_state.place_tenant(Vector2i(1, 1), bag_human)
	# Only the Zombie is left in the bag, so it must be the replacement.
	context.tenant_bag.bag = [bag_zombie]
	_answer_cells(context, [Vector2i(1, 1)])
	await TradeWithBagEffect.new().execute(context)
	_report(context.building_state.get_tenant_at(Vector2i(1, 1)) == bag_zombie, "trade: replacement took the cell")
	_report(context.tenant_bag.bag == [bag_human], "trade: old tenant is back in the bag (not the discard pile)")
	_report(context.tenant_bag.discard_pile.is_empty(), "trade: nothing discarded")
	_report(
		context.events.size() == 2
		and context.events[0].trigger == GameEvent.Trigger.REMOVAL
		and context.events[1].trigger == GameEvent.Trigger.RANDOM_PLACEMENT,
		"trade: REMOVAL then RANDOM_PLACEMENT events"
	)

	# The tenant sent away can never be its own replacement, even if it is
	# the only one in the bag afterwards.
	context = _make_context()
	context.tenant_bag.bag = []
	context.building_state.place_tenant(Vector2i(1, 1), context.tenant_bag.roster[0])
	await TradeWithBagEffect.new().execute(context)
	_report(context.events.is_empty(), "trade: empty bag fizzles, board untouched")
	_report(context.building_state.get_tenant_at(Vector2i(1, 1)) == context.tenant_bag.roster[0], "trade: target stays when bag is empty")

	context = _make_context()
	await TradeWithBagEffect.new().execute(context)
	_report(context.events.is_empty() and context.tenant_bag.bag.size() == 4, "trade: empty building draws nothing")

	# Same type is allowed: a different Human may replace a Human.
	context = _make_context()
	var human_bag: TenantBag = TenantBag.new()
	human_bag.setup([_res("human"), _res("human")])
	var human_state: BuildingState = BuildingState.new()
	human_state.setup(4, 4)
	context = ActionContext.new(human_bag, human_state, RunState.new())
	var first_human: TenantInstance = human_bag.roster[0]
	var second_human: TenantInstance = human_bag.roster[1]
	human_bag.bag = [second_human]
	human_state.place_tenant(Vector2i(0, 0), first_human)
	_answer_cells(context, [Vector2i(0, 0)])
	await TradeWithBagEffect.new().execute(context)
	_report(
		human_state.get_tenant_at(Vector2i(0, 0)) == second_human
		and human_bag.bag == [first_human],
		"trade: a different Human may replace a Human"
	)

	# --- Move ---
	context = _make_context()
	human = context.tenant_bag.roster[0]
	context.building_state.place_tenant(Vector2i(0, 0), human)
	_answer_cells(context, [Vector2i(0, 0), Vector2i(3, 2)])
	await MoveTenantEffect.new().execute(context)
	_report(
		context.building_state.is_empty(Vector2i(0, 0))
		and context.building_state.get_tenant_at(Vector2i(3, 2)) == human,
		"move: tenant moved to the chosen empty cell"
	)
	_report(context.events.is_empty(), "move: records no event")
	_report(not context.building_state.move_tenant(Vector2i(3, 2), Vector2i(3, 2)), "move: onto itself is rejected")

	# --- Playability: which cards can be played in which situations ---
	var card_names: Array[String] = ["recruit", "random_arrivals", "swap", "evict", "trade", "move"]
	var cards: Dictionary[String, ActionResource] = {}
	for card_name: String in card_names:
		cards[card_name] = load("res://main/data/actions/%s.tres" % card_name)

	# Empty building: only the placement cards work.
	context = _make_context()
	_report(cards["recruit"].can_play(context), "empty building: Recruit playable")
	_report(cards["random_arrivals"].can_play(context), "empty building: Random Arrivals playable")
	_report(not cards["swap"].can_play(context), "empty building: Swap unplayable")
	_report(not cards["evict"].can_play(context), "empty building: Evict unplayable")
	_report(not cards["trade"].can_play(context), "empty building: Trade unplayable")
	_report(not cards["move"].can_play(context), "empty building: Move unplayable")

	# One tenant: everything except Swap works.
	context.building_state.place_tenant(Vector2i(0, 0), context.tenant_bag.draw_random())
	_report(not cards["swap"].can_play(context), "1 tenant: Swap unplayable")
	_report(cards["evict"].can_play(context), "1 tenant: Evict playable")
	_report(cards["trade"].can_play(context), "1 tenant: Trade playable")
	_report(cards["move"].can_play(context), "1 tenant: Move playable")

	# Two tenants: Swap works.
	context.building_state.place_tenant(Vector2i(1, 0), context.tenant_bag.draw_random())
	_report(cards["swap"].can_play(context), "2 tenants: Swap playable")

	# Empty bag: nothing that needs a tenant from the bag works.
	context.tenant_bag.bag.clear()
	_report(not cards["recruit"].can_play(context), "empty bag: Recruit unplayable")
	_report(not cards["random_arrivals"].can_play(context), "empty bag: Random Arrivals unplayable")
	_report(not cards["trade"].can_play(context), "empty bag: Trade unplayable")
	_report(cards["move"].can_play(context) and cards["swap"].can_play(context), "empty bag: Move and Swap still playable")

	# Full building: no empty cell.
	context = _make_context()
	for index: int in range(16):
		context.building_state.place_tenant(
			Vector2i(index % 4, index / 4), TenantInstance.new(_res("human"))
		)
	_report(not cards["recruit"].can_play(context), "full building: Recruit unplayable")
	_report(not cards["random_arrivals"].can_play(context), "full building: Random Arrivals unplayable")
	_report(not cards["move"].can_play(context), "full building: Move unplayable")
	_report(cards["swap"].can_play(context) and cards["evict"].can_play(context), "full building: Swap and Evict playable")

	# --- Through the real game: Move changes the projected rent ---
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var swap_card: ActionResource = load("res://main/data/actions/swap.tres")
	game.action_deck.setup([swap_card, swap_card, swap_card, swap_card, swap_card])
	game.action_deck.start_round(5)

	var board: BuildingState = game.building.building_state
	board.place_tenant(Vector2i(0, 0), TenantInstance.new(_res("vampire")))
	board.place_tenant(Vector2i(1, 0), TenantInstance.new(_res("human")))
	board.place_tenant(Vector2i(3, 3), TenantInstance.new(_res("human")))
	_report(game.hud.projected_rent_label.text.begins_with("Projected rent: $35 "), "game: projection before swap")

	game.hud.action_card_selected.emit(swap_card)
	_report(game.is_resolving, "game: swap waits for the first click")
	_report(game.building.building_view.selectable_positions.size() == 3, "game: the 3 tenants are selectable")
	game.building.building_view.cell_chosen.emit(Vector2i(0, 0))
	game.building.building_view.cell_chosen.emit(Vector2i(3, 3))
	_report(not game.is_resolving, "game: swap finished after two clicks")
	_report(
		board.get_tenant_at(Vector2i(3, 3)).tenant_resource.tenant_name == "Vampire"
		and board.get_tenant_at(Vector2i(0, 0)).tenant_resource.tenant_name == "Human",
		"game: Vampire and Human traded cells"
	)
	# Vampire at (3,3) has no neighbors now: 10 + three Humans 30 = 40? No:
	# Humans at (0,0) and (1,0) pay 20, Vampire alone pays 10 -> 30.
	_report(game.hud.projected_rent_label.text.begins_with("Projected rent: $30 "), "game: projection updated after swap")


	# --- Unplayable cards in the real game ---
	game._start_round()
	game.action_deck.setup([swap_card, swap_card, swap_card, swap_card, swap_card])
	game.action_deck.start_round(5)
	game._refresh_hud()
	var first_button: Button = game.hud.hand_container.get_child(0)
	_report(first_button.disabled, "game: Swap button is disabled on an empty building")
	_report(first_button.modulate.r > first_button.modulate.g, "game: unplayable card is tinted red")
	var plays_before: int = game.round_state.plays_remaining
	game.hud.action_card_selected.emit(swap_card)
	_report(game.round_state.plays_remaining == plays_before, "game: clicking an unplayable card costs nothing")

	# After Recruit the only card left is a Swap, which needs 2 tenants.
	var recruit_card: ActionResource = load("res://main/data/actions/recruit.tres")
	# That swap-only hand on an empty building already ended the round.
	_report(not game.round_state.is_active, "game: a hand with nothing playable ends the round at its start")
	game.round_state.start_round(6)
	game.hud.set_round_active(true)
	game.action_deck.hand = [recruit_card]
	game.action_deck.draw_pile = [swap_card]
	game.action_deck.discard_pile = []
	game._refresh_hud()
	game.hud.action_card_selected.emit(recruit_card)
	game.tenant_choice_ui.cards_container.get_child(0).pressed.emit()
	game.building.building_view.cell_chosen.emit(Vector2i(0, 0))
	_report(game.building.building_state.tenants_by_position.size() == 1, "game: Recruit placed one tenant")
	_report(not game.round_state.is_active, "game: round ended because no card is playable")
	game._start_round()
	print("--- phase 5 check finished ---")
	get_tree().quit()
