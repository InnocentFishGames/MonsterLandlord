extends Node

# TEMPORARY scripted check of persistent bonuses and packs.
# Run: dev/phase7_check.tscn (F6).


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _res(file_name: String) -> TenantResource:
	return load("res://main/data/tenants/%s.tres" % file_name)


func _ready() -> void:
	var ledger: PersistentBonus = load("res://main/data/bonuses/ledger.tres")
	var crypt: PersistentBonus = load("res://main/data/bonuses/crypt_fee.tres")
	var tenant_pack: PackResource = load("res://main/data/packs/tenant_pack.tres")
	var action_pack: PackResource = load("res://main/data/packs/action_pack.tres")

	_report(tenant_pack.validate() and action_pack.validate(), "both packs are valid")

	# --- Bonuses in a chain ---
	var board: BuildingState = BuildingState.new()
	board.setup(4, 4)
	board.place_tenant(Vector2i(0, 0), TenantInstance.new(_res("zombie")))
	board.place_tenant(Vector2i(1, 0), TenantInstance.new(_res("vampire")))
	board.place_tenant(Vector2i(2, 0), TenantInstance.new(_res("human")))
	var round_state: RoundState = RoundState.new()
	round_state.start_round(6)
	var bonuses: Array[PersistentBonus] = [crypt, ledger]
	var ran: int = ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.ROUND_END)],
		AbilityContext.new(board, round_state, bonuses)
	)
	# Zombie 2 + Vampire (10 + 5 for the Human) 15 + Human 10 = 27.
	# Crypt Fee: Zombie + Vampire are Undead = 2 * 4 = 8. Ledger: 10.
	_report(round_state.rent_total == 27 + 8 + 10, "bonuses add to rent (27 + 8 + 10)")
	_report(ran == 4 + 2, "4 tenant abilities + 2 bonuses ran")
	_report(round_state.rent_log.size() >= 2, "bonuses are logged")
	_report(
		round_state.rent_log[-2].begins_with("Bonus Crypt Fee")
		and round_state.rent_log[-1].begins_with("Bonus Landlord"),
		"tenants resolve first, then bonuses in the order bought"
	)

	var no_bonus_round: RoundState = RoundState.new()
	no_bonus_round.start_round(6)
	ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.ROUND_END)],
		AbilityContext.new(board, no_bonus_round)
	)
	_report(no_bonus_round.rent_total == 27, "no bonuses: tenants only")

	# A bonus with nothing to count adds nothing.
	var empty_board: BuildingState = BuildingState.new()
	empty_board.setup(4, 4)
	var empty_round: RoundState = RoundState.new()
	empty_round.start_round(6)
	ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.ROUND_END)],
		AbilityContext.new(empty_board, empty_round, [crypt])
	)
	_report(empty_round.rent_total == 0, "Crypt Fee with no Undead adds nothing")

	# --- Shop: bonuses and packs ---
	var shop_state: ShopState = ShopState.new()
	shop_state.setup([_res("human")], [], [ledger, crypt], [tenant_pack, action_pack])
	var run_state: RunState = RunState.new()
	run_state.start_run(8, 60, 20)
	var tenant_bag: TenantBag = TenantBag.new()
	tenant_bag.setup([_res("human"), _res("human")])
	var action_deck: ActionDeck = ActionDeck.new()
	action_deck.setup([load("res://main/data/actions/recruit.tres")])

	shop_state.roll_offers(1, 0, 2, 2, 0, run_state.bonuses)
	_report(shop_state.offers.size() == 1 + 2 + 2, "offers: 1 tenant + 2 bonuses + 2 packs")

	run_state.add_shop_money(30)
	var bonus_offer: ShopOffer = null
	var pack_offer: ShopOffer = null
	var action_pack_offer: ShopOffer = null
	for offer: ShopOffer in shop_state.offers:
		if offer.kind == ShopOffer.Kind.BONUS and bonus_offer == null:
			bonus_offer = offer
		elif offer.kind == ShopOffer.Kind.PACK:
			if offer.pack.is_tenant_pack():
				pack_offer = offer
			else:
				action_pack_offer = offer

	_report(shop_state.try_buy(bonus_offer, run_state, tenant_bag, action_deck), "buying a bonus works")
	_report(run_state.bonuses.size() == 1 and run_state.bonuses[0] == bonus_offer.bonus, "bonus joins the run")

	shop_state.roll_offers(1, 0, 2, 0, 0, run_state.bonuses)
	var offered_bonuses: int = 0
	for offer: ShopOffer in shop_state.offers:
		if offer.kind == ShopOffer.Kind.BONUS:
			offered_bonuses += 1
			_report(offer.bonus != bonus_offer.bonus, "an owned bonus is not offered again")
	_report(offered_bonuses == 1, "only the unowned bonus is offered")

	# Packs
	shop_state.roll_offers(0, 0, 0, 2, 0, run_state.bonuses)
	for offer: ShopOffer in shop_state.offers:
		if offer.pack.is_tenant_pack():
			pack_offer = offer
		else:
			action_pack_offer = offer

	var money_before: int = run_state.shop_money
	_report(shop_state.try_buy(pack_offer, run_state, tenant_bag, action_deck), "buying a tenant pack works")
	_report(run_state.shop_money == money_before - 5, "pack price taken")
	_report(tenant_bag.roster.size() == 2, "paying alone does not add a tenant")
	var choices: Array[ShopOffer] = shop_state.roll_pack_choices(pack_offer)
	_report(choices.size() == 3, "tenant pack shows 3 choices")
	var kinds_ok: bool = true
	for choice: ShopOffer in choices:
		kinds_ok = kinds_ok and choice.kind == ShopOffer.Kind.TENANT
	_report(kinds_ok, "tenant pack choices are tenants")
	shop_state.take_pack_choice(choices[0], tenant_bag, action_deck)
	_report(tenant_bag.roster.size() == 3, "picked tenant joins the roster")

	_report(shop_state.try_buy(action_pack_offer, run_state, tenant_bag, action_deck), "buying an action pack works")
	var action_choices: Array[ShopOffer] = shop_state.roll_pack_choices(action_pack_offer)
	_report(action_choices.size() == 3 and action_choices[0].kind == ShopOffer.Kind.ACTION, "action pack shows 3 actions")
	shop_state.take_pack_choice(action_choices[1], tenant_bag, action_deck)
	_report(action_deck.cards.size() == 2, "picked action joins the deck")

	run_state.start_run(8, 60, 20)
	_report(run_state.bonuses.is_empty(), "a new run forgets the bonuses")

	# --- Through the real game ---
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.run_state.starting_goal = 1
	game.run_state.add_bonus(ledger)
	game._refresh_hud()
	_report(game.hud.bonuses_label.text == "Bonuses: Landlord's Ledger", "HUD lists owned bonuses")
	game.building.building_state.place_tenant(Vector2i(0, 0), TenantInstance.new(_res("human")))
	_report(game.hud.projected_rent_label.text.begins_with("Projected rent: $20 "), "projection includes bonuses (10 + 10)")
	game.hud.end_round_requested.emit()
	_report(game.round_state.rent_total == 20, "real round pays tenant + bonus")
	_report(game.shop_ui.shop_panel.visible, "shop open")
	_report(game.shop_ui.extra_row.get_child_count() == 5, "shop extra row: the unowned bonus + 2 packs + 2 items")

	var real_pack: ShopOffer = null
	for offer: ShopOffer in game.shop_state.offers:
		if offer.kind == ShopOffer.Kind.PACK and offer.pack.is_tenant_pack():
			real_pack = offer
	game.shop_ui.offer_selected.emit(real_pack)
	_report(game.run_state.shop_money == 0, "real shop: pack bought with the 5 shop money")
	_report(not game.shop_ui.continue_button.visible, "must pick from the pack before continuing")
	_report(game.shop_ui.title_label.text == "Choose one", "pack screen says Choose one")
	_report(game.shop_ui.tenant_row.get_child_count() == 3, "pack screen shows 3 tenants")
	game.shop_ui.tenant_row.get_child(0).pressed.emit()
	_report(game.tenant_bag.roster.size() == 11, "real shop: picked tenant joined the roster")
	_report(game.shop_ui.continue_button.visible, "back to the shop after picking")
	_report(game.shop_ui.title_label.text == "Shop", "title is Shop again")

	print("--- phase 7 check finished ---")
	get_tree().quit()
