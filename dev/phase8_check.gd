extends Node

# TEMPORARY scripted check of one-time-use items.
# Run: dev/phase8_check.tscn (F6).


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _res(file_name: String) -> TenantResource:
	return load("res://main/data/tenants/%s.tres" % file_name)


func _ready() -> void:
	var piggy: ItemResource = load("res://main/data/items/piggy_bank.tres")
	var hike: ItemResource = load("res://main/data/items/rent_hike.tres")
	_report(piggy.validate() and hike.validate(), "both items are valid")

	# --- RunState slots ---
	var run_state: RunState = RunState.new()
	run_state.start_run(8, 60, 20)
	_report(run_state.add_item(piggy) and run_state.add_item(hike), "two items fit")
	_report(not run_state.has_free_item_slot(), "no free slot with 2 items")
	_report(not run_state.add_item(piggy) and run_state.items.size() == 2, "a third item is rejected")
	run_state.remove_item(0)
	_report(run_state.items == [hike] and run_state.has_free_item_slot(), "removing an item frees a slot")
	run_state.start_run(8, 60, 20)
	_report(run_state.items.is_empty(), "a new run empties the slots")

	# --- Piggy Bank ---
	var tenant_bag: TenantBag = TenantBag.new()
	tenant_bag.setup([_res("human"), _res("zombie")])
	var board: BuildingState = BuildingState.new()
	board.setup(4, 4)
	var context: ActionContext = ActionContext.new(tenant_bag, board, run_state)
	_report(not piggy.can_use(context), "Piggy Bank unusable with 0 shop money")
	run_state.add_shop_money(7)
	_report(piggy.can_use(context), "Piggy Bank usable with money")
	await piggy.effects[0].execute(context)
	_report(run_state.shop_money == 14, "Piggy Bank doubles 7 to 14")

	# --- Rent Hike ---
	_report(not hike.can_use(context), "Rent Hike unusable on an empty board")
	var human: TenantInstance = tenant_bag.roster[0]
	var zombie: TenantInstance = tenant_bag.roster[1]
	board.place_tenant(Vector2i(0, 0), human)
	board.place_tenant(Vector2i(1, 0), zombie)
	_report(hike.can_use(context), "Rent Hike usable with a tenant on the board")

	var answers: Array[Vector2i] = [Vector2i(1, 0)]
	context.cell_choice_requested.connect(
		func(_valid: Array[Vector2i], _prompt: String) -> void:
			context.submit_cell_choice.call_deferred(answers.pop_front())
	)
	await hike.effects[0].execute(context)
	_report(zombie.base_rent_bonus == 10 and human.base_rent_bonus == 0, "only the chosen tenant gets +10")
	_report(context.events.is_empty(), "Rent Hike raises no event")

	var round_state: RoundState = RoundState.new()
	round_state.start_round(6)
	ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.ROUND_END)],
		AbilityContext.new(board, round_state)
	)
	# Human 10. Zombie (2 + 10) doubled once for the earlier Zombie? The
	# Human is not a Zombie, so no doubling: 12.
	_report(round_state.rent_total == 10 + 12, "Zombie base rent is 2 + 10 = 12")

	tenant_bag.return_all_to_bag()
	_report(zombie.base_rent_bonus == 10, "base rent bonus lasts after the round")

	# --- Shop ---
	var shop_state: ShopState = ShopState.new()
	shop_state.setup([], [], [], [], [piggy, hike])
	shop_state.roll_offers(0, 0, 0, 0, 2, [])
	_report(shop_state.offers.size() == 2, "shop rolls 2 item offers")
	run_state.start_run(8, 60, 20)
	run_state.add_shop_money(30)
	var action_deck: ActionDeck = ActionDeck.new()
	action_deck.setup([load("res://main/data/actions/recruit.tres")])
	_report(shop_state.try_buy(shop_state.offers[0], run_state, tenant_bag, action_deck), "buying an item works")
	_report(run_state.items.size() == 1 and run_state.shop_money == 30 - shop_state.offers[0].price, "item in slot, price paid")
	_report(shop_state.try_buy(shop_state.offers[1], run_state, tenant_bag, action_deck), "second item fits")
	shop_state.roll_offers(0, 0, 0, 0, 2, [])
	var money_before: int = run_state.shop_money
	_report(not shop_state.try_buy(shop_state.offers[0], run_state, tenant_bag, action_deck), "full slots reject the purchase")
	_report(run_state.shop_money == money_before, "no money taken when slots are full")

	# --- Through the real game ---
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	_report(game.hud.items_container.get_child_count() == 2, "HUD shows 2 empty slots")
	_report(game.hud.items_container.get_child(0).disabled, "empty slot is disabled")

	game.run_state.add_item(piggy)
	game.run_state.add_item(hike)
	game.run_state.add_shop_money(5)
	game._refresh_hud()
	var piggy_button: Button = game.hud.items_container.get_child(0)
	var hike_button: Button = game.hud.items_container.get_child(1)
	_report(not piggy_button.disabled, "Piggy Bank slot is usable")
	_report(hike_button.disabled and hike_button.modulate.r > hike_button.modulate.g, "Rent Hike is red on an empty board")

	game.hud.item_selected.emit(1)
	_report(game.run_state.items.size() == 2, "clicking an unusable item does nothing")

	game.hud.item_selected.emit(0)
	_report(game.run_state.shop_money == 10, "using Piggy Bank doubled shop money (5 to 10)")
	_report(game.run_state.items == [hike], "Piggy Bank is gone after use")
	_report(game.hud.items_container.get_child(1).text == "Empty slot", "its slot is empty now")

	# Rent Hike with a real click.
	var human_resource: TenantResource = _res("human")
	game.building.building_state.place_tenant(Vector2i(2, 2), TenantInstance.new(human_resource))
	game._refresh_hud()
	_report(game.hud.projected_rent_label.text.begins_with("Projected rent: $10 "), "projection before Rent Hike")
	game.hud.item_selected.emit(0)
	_report(game.is_resolving, "Rent Hike waits for a click")
	_report(not game.hud.items_container.visible and not game.hud.hand_container.visible, "items and hand are hidden while resolving")
	_report(game.building.building_view.selectable_positions == [Vector2i(2, 2)], "only the tenant is selectable")
	game.building.building_view.cell_chosen.emit(Vector2i(2, 2))
	_report(not game.is_resolving, "Rent Hike finished")
	_report(game.building.building_state.get_tenant_at(Vector2i(2, 2)).base_rent_bonus == 10, "tenant got +10")
	_report(game.hud.projected_rent_label.text.begins_with("Projected rent: $20 "), "projection updated to 20")
	_report(game.run_state.items.is_empty(), "both items used up")
	_report(game.hud.items_container.visible, "items visible again after resolving")

	# Not usable once the round is over.
	game.run_state.add_item(piggy)
	game.round_state.end_round()
	var money_now: int = game.run_state.shop_money
	game.hud.item_selected.emit(0)
	_report(game.run_state.shop_money == money_now, "items cannot be used after the round ends")

	print("--- phase 8 check finished ---")
	get_tree().quit()
