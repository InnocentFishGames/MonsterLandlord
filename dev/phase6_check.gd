extends Node

# TEMPORARY scripted check of the run, the payment check and the shop.
# Run: dev/phase6_check.tscn (F6).


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _new_game() -> Game:
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	return game


func _ready() -> void:
	# --- RunState ---
	var run_state: RunState = RunState.new()
	run_state.start_run(8, 60, 20)
	_report(run_state.get_goal() == 60, "round 1 goal is 60")
	run_state.advance_round()
	_report(run_state.get_goal() == 80, "round 2 goal is 80")
	run_state.current_round = 8
	_report(run_state.get_goal() == 200 and run_state.is_final_round(), "round 8 goal is 200 and is final")
	run_state.add_shop_money(5)
	_report(not run_state.try_spend_shop_money(6), "cannot overspend shop money")
	_report(run_state.try_spend_shop_money(5) and run_state.shop_money == 0, "spending shop money works")

	# --- ShopState ---
	var human: TenantResource = load("res://main/data/tenants/human.tres")
	var vampire: TenantResource = load("res://main/data/tenants/vampire.tres")
	var recruit: ActionResource = load("res://main/data/actions/recruit.tres")
	var swap: ActionResource = load("res://main/data/actions/swap.tres")
	var shop_state: ShopState = ShopState.new()
	_report(shop_state.setup([human, vampire], [recruit, swap]), "shop setup succeeds")
	shop_state.roll_offers(5, 1, 0, 0, [])
	_report(shop_state.offers.size() == 3, "offers capped by pool size (2 tenants + 1 action)")

	var tenant_bag: TenantBag = TenantBag.new()
	tenant_bag.setup([human, human])
	var action_deck: ActionDeck = ActionDeck.new()
	action_deck.setup([recruit])
	run_state.start_run(8, 60, 20)
	run_state.add_shop_money(5)
	var tenant_offer: ShopOffer = null
	var action_offer: ShopOffer = null
	for offer: ShopOffer in shop_state.offers:
		if offer.kind == ShopOffer.Kind.TENANT:
			tenant_offer = offer
		else:
			action_offer = offer
	_report(shop_state.try_buy(tenant_offer, run_state, tenant_bag, action_deck), "buying a tenant works")
	_report(tenant_bag.roster.size() == 3 and tenant_bag.get_bag_size() == 3, "bought tenant joins roster and bag")
	_report(run_state.shop_money == 1, "price was taken (5 - 4)")
	_report(not shop_state.try_buy(tenant_offer, run_state, tenant_bag, action_deck), "sold offer cannot be bought again")
	_report(not shop_state.try_buy(action_offer, run_state, tenant_bag, action_deck), "unaffordable offer is rejected")
	_report(action_deck.cards.size() == 1 and run_state.shop_money == 1, "rejected purchase changes nothing")
	run_state.add_shop_money(10)
	_report(shop_state.try_buy(action_offer, run_state, tenant_bag, action_deck), "buying an action works")
	_report(action_deck.cards.size() == 2, "bought card joins the deck")

	# --- Failing the payment check ---
	var game: Game = await _new_game()
	_report(game.hud.run_label.text.begins_with("Round 1 / 8"), "HUD shows round 1 of 8")
	_report(game.hud.projected_rent_label.text.ends_with("goal $60"), "projection shows the goal")
	game.building.building_state.place_tenant(Vector2i(0, 0), TenantInstance.new(human))
	game.hud.end_round_requested.emit()
	_report(game.round_state.rent_total == 10, "rent 10 paid")
	_report(game.hud.restart_button.visible, "missing the goal ends the run (restart button)")
	_report(not game.shop_ui.shop_panel.visible, "no shop after a failed round")
	_report(game.hud.prompt_label.text.begins_with("Run over"), "run over message shown")

	# --- Restart ---
	game.tenant_bag.add_to_roster(vampire)
	game.hud.restart_requested.emit()
	_report(not game.hud.restart_button.visible, "restart hides the restart button")
	_report(game.run_state.current_round == 1 and game.run_state.shop_money == 0, "restart: round 1, no shop money")
	_report(game.tenant_bag.roster.size() == 10, "restart: roster back to the starting 10")
	_report(game.round_state.is_active, "restart: a new round is running")

	# --- Passing: shop opens ---
	game.run_state.starting_goal = 5
	game.building.building_state.place_tenant(Vector2i(0, 0), TenantInstance.new(human))
	game.hud.end_round_requested.emit()
	_report(game.shop_ui.shop_panel.visible, "passing a round opens the shop")
	_report(game.run_state.shop_money == 5, "passing gives 5 shop money")
	_report(game.shop_ui.tenant_row.get_child_count() == 3, "shop shows 3 tenant offers")
	_report(game.shop_ui.action_row.get_child_count() == 3, "shop shows 3 action offers")
	_report(not game.hud.restart_button.visible, "no restart button while shopping")

	var bought: ShopOffer = null
	for offer: ShopOffer in game.shop_state.offers:
		if offer.kind == ShopOffer.Kind.TENANT:
			bought = offer
			break
	game.shop_ui.offer_selected.emit(bought)
	_report(game.run_state.shop_money == 1, "buying in the real shop spends shop money")
	_report(game.tenant_bag.roster.size() == 11, "real shop: roster grew to 11")

	game.shop_ui.continue_requested.emit()
	_report(not game.shop_ui.shop_panel.visible, "continue closes the shop")
	_report(game.run_state.current_round == 2, "now round 2")
	_report(game.run_state.get_goal() == 25, "round 2 goal is 25 (5 + 20)")
	_report(game.building.building_state.get_occupied_positions().is_empty(), "building was cleaned up")
	_report(game.tenant_bag.get_bag_size() == 11, "bought tenant is in the bag for round 2")
	_report(game.round_state.is_active, "round 2 is running")

	# --- Winning ---
	game.run_state.current_round = 8
	game.run_state.goal_increase = 0
	game.building.building_state.place_tenant(Vector2i(0, 0), TenantInstance.new(human))
	game.hud.end_round_requested.emit()
	_report(game.hud.prompt_label.text.begins_with("You won"), "passing round 8 wins the run")
	_report(game.hud.restart_button.visible, "win offers a new run")
	_report(not game.shop_ui.shop_panel.visible, "no shop after the final round")

	print("--- phase 6 check finished ---")
	get_tree().quit()
