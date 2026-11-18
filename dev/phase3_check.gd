extends Node

# TEMPORARY. Run: dev/phase3_check.tscn (F6).


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _make_context(tenant_count: int) -> ActionContext:
	var human: TenantResource = load("res://main/data/tenants/human.tres")
	var starting: Array[TenantResource] = []
	for index: int in range(tenant_count):
		starting.append(human)

	var bag: TenantBag = TenantBag.new()
	if tenant_count > 0:
		bag.setup(starting)
	var state: BuildingState = BuildingState.new()
	state.setup(4, 4)

	return ActionContext.new(bag, state, RunState.new())


func _fill_cells(context: ActionContext, cell_count: int) -> void:
	var human: TenantResource = load("res://main/data/tenants/human.tres")
	var positions: Array[Vector2i] = context.building_state.get_positions_in_order()
	for index: int in range(cell_count):
		context.building_state.place_tenant(positions[index], TenantInstance.new(human))


func _ready() -> void:
	await _check_random_effect()
	await _check_choose_effect()
	await _check_game_flow()
	print("--- phase 3 check finished ---")
	get_tree().quit()


func _check_random_effect() -> void:
	var effect: PlaceRandomTenantsEffect = PlaceRandomTenantsEffect.new()

	var context: ActionContext = _make_context(3)
	await effect.execute(context)
	_report(context.building_state.tenants_by_position.size() == 2, "random: 2 tenants placed")
	_report(context.tenant_bag.get_bag_size() == 1, "random: bag has 1 left")

	context = _make_context(3)
	_fill_cells(context, 15)
	await effect.execute(context)
	_report(context.building_state.get_empty_positions().is_empty(), "random: 1 empty cell gets filled")
	_report(context.tenant_bag.get_discard_size() == 1, "random: the tenant that did not fit is discarded")
	_report(context.tenant_bag.get_bag_size() == 1, "random: remaining bag tenant untouched")

	context = _make_context(3)
	_fill_cells(context, 16)
	await effect.execute(context)
	_report(context.tenant_bag.get_discard_size() == 2, "random: full building discards both drawn tenants")

	context = _make_context(1)
	await effect.execute(context)
	_report(context.building_state.tenants_by_position.size() == 1, "random: only 1 tenant left, only 1 placed")

	context = _make_context(1)
	context.tenant_bag.bag.clear()
	await effect.execute(context)
	_report(context.building_state.tenants_by_position.is_empty(), "random: empty bag fizzles quietly")


func _check_choose_effect() -> void:
	var effect: ChoosePlaceTenantEffect = ChoosePlaceTenantEffect.new()

	var context: ActionContext = _make_context(5)
	var offered: Array[Array] = [[]]
	context.tenant_choice_requested.connect(
		func(options: Array[TenantInstance]) -> void:
			offered[0] = options
			context.submit_tenant_choice.call_deferred(options[1])
	)
	context.cell_choice_requested.connect(
		func(valid: Array[Vector2i], _prompt: String) -> void:
			context.submit_cell_choice.call_deferred(Vector2i(2, 2))
	)
	await effect.execute(context)
	_report(offered[0].size() == 3, "choose: 3 tenants offered")
	_report(context.building_state.get_tenant_at(Vector2i(2, 2)) == offered[0][1], "choose: chosen tenant is on the chosen cell")
	_report(context.tenant_bag.get_discard_size() == 2, "choose: the 2 unchosen tenants are discarded")
	_report(context.tenant_bag.get_bag_size() == 2, "choose: bag has 2 left")

	context = _make_context(5)
	_fill_cells(context, 16)
	await effect.execute(context)
	_report(context.tenant_bag.get_discard_size() == 3, "choose: full building discards all 3 without asking")


func _check_game_flow() -> void:
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame

	var recruit: ActionResource = load("res://main/data/actions/recruit.tres")
	var arrivals: ActionResource = load("res://main/data/actions/random_arrivals.tres")
	var deck: ActionDeck = game.action_deck
	deck.hand.append(recruit)
	deck.hand.append(arrivals)

	# --- Recruit through the real interface ---
	game.hud.action_card_selected.emit(recruit)
	await get_tree().process_frame

	_report(game.is_resolving, "game: card is resolving while waiting for the player")
	_report(game.tenant_choice_ui.choices_panel.visible, "game: tenant choice panel is visible")
	_report(game.tenant_choice_ui.cards_container.get_child_count() == 3, "game: 3 tenant cards shown")
	_report(not game.hud.hand_container.visible, "game: hand hidden while resolving")
	_report(game.hud.end_round_button.disabled, "game: End Round disabled while resolving")
	_report(game.tenant_bag.get_bag_size() == 7, "game: 3 tenants drawn from the bag")

	game.hud.end_round_requested.emit()
	_report(game.round_state.is_active, "game: End Round ignored while resolving")

	game.tenant_choice_ui.cards_container.get_child(1).pressed.emit()
	await get_tree().process_frame

	_report(not game.tenant_choice_ui.choices_panel.visible, "game: choice panel closed after choosing")
	_report(game.tenant_bag.get_discard_size() == 2, "game: 2 unchosen tenants discarded")
	_report(game.building.building_view.selectable_positions.size() == 16, "game: all 16 cells highlighted")
	_report(game.hud.prompt_label.text.begins_with("Place "), "game: prompt tells the player to click a cell")

	# A cell nobody offered must be ignored and the card keeps waiting.
	game.building.building_view.cell_chosen.emit(Vector2i(9, 9))
	await get_tree().process_frame
	_report(game.is_resolving, "game: an invalid cell is ignored")

	game.building.building_view.cell_chosen.emit(Vector2i(1, 0))
	await get_tree().process_frame

	_report(game.building.building_state.get_tenant_at(Vector2i(1, 0)) != null, "game: tenant placed on (1,0)")
	_report(not game.is_resolving, "game: card finished resolving")
	_report(game.hud.hand_container.visible, "game: hand visible again")
	_report(game.round_state.plays_remaining == 5, "game: Recruit cost exactly 1 play")

	# --- Random Arrivals ---
	game.hud.action_card_selected.emit(arrivals)
	await get_tree().process_frame
	_report(game.building.building_state.tenants_by_position.size() == 3, "game: Random Arrivals placed 2 more tenants")
	_report(not game.is_resolving, "game: Random Arrivals needs no clicks")

	# --- Cleanup ---
	game.round_state.end_round()
	game._start_round()
	_report(game.building.building_state.get_empty_positions().size() == 16, "game: next round empties the building")
	_report(game.tenant_bag.get_bag_size() == 10 and game.tenant_bag.get_discard_size() == 0, "game: all 10 tenants back in the bag")
