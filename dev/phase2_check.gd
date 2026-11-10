extends Node

# TEMPORARY scripted play-through of the phase 2 round flow.
# Run: dev/phase2_check.tscn (F6).


func _report(passed: bool, description: String) -> void:
	print(("PASS  " if passed else "FAIL  ") + description)


func _ready() -> void:
	var game: Game = load("res://main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame

	var deck: ActionDeck = game.action_deck
	var round_state: RoundState = game.round_state

	_report(deck.hand.size() == 5, "round starts with a hand of 5")
	_report(round_state.plays_remaining == 6, "round starts with 6 plays")
	_report(game.hud.hand_container.get_child_count() == 5, "HUD shows 5 card buttons")
	_report(game.building.building_state.columns == 4, "building is 4 wide")

	# The real cards wait for clicks (tested in phase3_check), so swap in
	# plain cards with no effects to test only the round flow.
	var blank_card: ActionResource = ActionResource.new()
	deck.setup([blank_card, blank_card, blank_card, blank_card, blank_card])
	deck.start_round(5)

	var card: ActionResource = deck.hand[0]
	game.hud.action_card_selected.emit(card)
	_report(round_state.plays_remaining == 5, "playing a card spends 1 play")
	_report(deck.hand.size() == 5, "replacement card drawn (hand back to 5)")
	# Hand = whole deck, so the draw pile is empty and the replacement draw
	# reshuffles the just-discarded card straight back (per the rules).
	_report(deck.discard_pile.is_empty(), "empty draw pile reshuffled the played card back in")
	_report(
		deck.hand.size() + deck.draw_pile.size() + deck.discard_pile.size() == 5,
		"all 5 cards accounted for"
	)

	for index: int in range(5):
		game.hud.action_card_selected.emit(deck.hand[0])

	_report(round_state.plays_remaining == 0, "6 plays used")
	_report(not round_state.is_active, "round ended when the last play was used")
	_report(not game.hud.hand_container.visible, "hand hidden after round end")

	var plays_after_end: int = round_state.plays_remaining
	game.hud.action_card_selected.emit(deck.hand[0])
	_report(round_state.plays_remaining == plays_after_end, "click after round end is ignored")

	game._start_round()
	_report(round_state.is_active and round_state.plays_remaining == 6, "next round restores 6 plays")
	_report(deck.hand.size() == 5 and deck.discard_pile.is_empty(), "next round redeals the full deck")
	_report(game.tenant_bag.get_bag_size() == 10, "tenant bag full (10)")

	game.hud.end_round_requested.emit()
	_report(not round_state.is_active, "End Round button ends the round early")

	print("--- phase 2 check finished ---")
	get_tree().quit()
