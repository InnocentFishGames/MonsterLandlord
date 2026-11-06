extends Node

# TEMPORARY. Delete the dev folder once phase 1 is confirmed.
# Run it by opening dev/phase1_check.tscn and pressing F6 (Run Current Scene).
# Results are printed in the Output panel. Each line starts with PASS or FAIL.


func _ready() -> void:
	_check_tenant_bag()
	_check_action_deck()
	_check_building_state()
	_check_round_state()

	print("--- phase 1 check finished. Close the window when done. ---")


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _check_tenant_bag() -> void:
	var human: TenantResource = load("res://main/data/tenants/human.tres")
	var zombie: TenantResource = load("res://main/data/tenants/zombie.tres")

	var tenant_bag: TenantBag = TenantBag.new()
	var starting: Array[TenantResource] = [human, human, zombie]

	_report(tenant_bag.setup(starting), "bag setup succeeds")
	_report(tenant_bag.get_bag_size() == 3, "bag starts with 3 tenants")

	var first: TenantInstance = tenant_bag.draw_random()
	var second: TenantInstance = tenant_bag.draw_random()
	var third: TenantInstance = tenant_bag.draw_random()

	_report(
		first != second and second != third and first != third,
		"3 draws give 3 different tenants (no replacement)"
	)
	_report(tenant_bag.draw_random() == null, "4th draw from empty bag is null")

	tenant_bag.discard(first)
	_report(tenant_bag.get_discard_size() == 1, "discard pile has 1 tenant")
	_report(tenant_bag.get_bag_size() == 0, "discarded tenant is not drawable")

	tenant_bag.return_all_to_bag()
	_report(
		tenant_bag.get_bag_size() == 3 and tenant_bag.get_discard_size() == 0,
		"return_all_to_bag restores all 3 tenants"
	)

	_report(not tenant_bag.setup([]), "empty starting roster is rejected")


func _make_card(card_name: String) -> ActionResource:
	var card: ActionResource = ActionResource.new()
	card.action_name = card_name
	return card


func _check_action_deck() -> void:
	var starting: Array[ActionResource] = [
		_make_card("A"), _make_card("B"), _make_card("C"),
		_make_card("D"), _make_card("E")
	]

	var deck: ActionDeck = ActionDeck.new()
	_report(deck.setup(starting), "deck setup succeeds")

	deck.start_round(3)
	_report(deck.hand.size() == 3, "opening hand is 3 cards")
	_report(deck.draw_pile.size() == 2, "draw pile has 2 cards left")

	var played: ActionResource = deck.hand[0]
	_report(deck.begin_play(played), "can play a card from the hand")
	_report(deck.hand.size() == 2, "played card left the hand")
	_report(
		deck.discard_pile.is_empty(),
		"card is NOT in the discard pile while resolving"
	)
	_report(not deck.begin_play(deck.hand[0]), "cannot start a second play while resolving")

	# Draw everything left, including trying to draw past the end.
	var drawn: int = deck.draw_cards(10)
	_report(drawn == 2, "drawing 10 with only 2 available draws 2")
	_report(
		not deck.hand.has(played),
		"the resolving card could not draw itself back"
	)

	deck.finish_play()
	_report(deck.discard_pile.has(played), "finished card is now in the discard pile")

	# Draw pile is empty now, so this must reshuffle the discard pile.
	var hand_before: Array[ActionResource] = deck.hand.duplicate()
	var reshuffled_draw: int = deck.draw_cards(1)
	_report(reshuffled_draw == 1 and deck.hand.has(played), "empty draw pile reshuffles the discard pile")
	_report(
		deck.hand.size() == hand_before.size() + 1,
		"cards already in hand stayed in hand during the reshuffle"
	)

	deck.start_round(5)
	_report(
		deck.hand.size() == 5 and deck.discard_pile.is_empty(),
		"start_round gathers all 5 cards back into a new hand"
	)

	_report(not deck.setup([]), "empty starting deck is rejected")


func _check_building_state() -> void:
	var human: TenantResource = load("res://main/data/tenants/human.tres")
	var building_state: BuildingState = BuildingState.new()

	_report(not building_state.setup(0, 4), "zero columns rejected")
	_report(building_state.setup(4, 4), "4x4 building setup succeeds")
	_report(building_state.get_empty_positions().size() == 16, "16 empty cells")

	var order: Array[Vector2i] = building_state.get_positions_in_order()
	_report(
		order[0] == Vector2i(0, 0)
		and order[1] == Vector2i(1, 0)
		and order[4] == Vector2i(0, 1)
		and order[15] == Vector2i(3, 3),
		"cell order is left-to-right, then next row down"
	)

	var tenant: TenantInstance = TenantInstance.new(human)
	_report(building_state.place_tenant(Vector2i(1, 1), tenant), "can place on an empty cell")
	_report(
		building_state.get_tenant_at(Vector2i(1, 1)) == tenant,
		"get_tenant_at returns the placed tenant"
	)
	_report(
		not building_state.place_tenant(Vector2i(1, 1), TenantInstance.new(human)),
		"occupied cell rejects a second tenant"
	)
	_report(building_state.get_empty_positions().size() == 15, "15 empty cells after one placement")
	_report(not building_state.place_tenant(Vector2i(4, 0), tenant), "out-of-range cell rejected")
	_report(building_state.remove_tenant(Vector2i(1, 1)) == tenant, "remove returns the tenant")
	_report(building_state.remove_tenant(Vector2i(1, 1)) == null, "removing an empty cell returns null")

	building_state.place_tenant(Vector2i(0, 0), tenant)
	building_state.clear()
	_report(building_state.get_empty_positions().size() == 16, "clear empties the building")


func _check_round_state() -> void:
	var round_state: RoundState = RoundState.new()
	var ended_count: Array[int] = [0]
	var last_plays: Array[int] = [-1]

	round_state.round_ended.connect(func() -> void: ended_count[0] += 1)
	round_state.plays_changed.connect(func(plays: int) -> void: last_plays[0] = plays)

	_report(not round_state.start_round(0), "zero plays rejected")
	_report(not round_state.spend_plays(1), "cannot spend before the round starts")
	_report(round_state.start_round(2), "round starts with 2 plays")
	_report(last_plays[0] == 2, "plays_changed announced 2")
	_report(round_state.spend_plays(1) and last_plays[0] == 1, "spend 1 play leaves 1")
	_report(not round_state.spend_plays(2), "cannot spend more plays than remain")
	round_state.add_plays(3)
	_report(round_state.plays_remaining == 4, "add_plays grants extra plays")
	round_state.end_round()
	round_state.end_round()
	_report(ended_count[0] == 1, "round_ended announced exactly once")
	_report(not round_state.spend_plays(1), "cannot spend plays after the round ends")
