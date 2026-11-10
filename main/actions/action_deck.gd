class_name ActionDeck
extends RefCounted


# The player's action cards for the whole run, and where each card is during
# the current round.
#
# `cards` is the source of truth for "which cards does the player own".
# During a round every card is in exactly one of: draw pile, hand, discard
# pile, or "currently resolving" (the card being played).

var cards: Array[ActionResource] = []
var draw_pile: Array[ActionResource] = []
var hand: Array[ActionResource] = []
var discard_pile: Array[ActionResource] = []

# The card being played right now. It is not in the hand and not yet in the
# discard pile, so a reshuffle can never pull it back into a draw by itself.
var resolving_card: ActionResource = null


func setup(starting_cards: Array[ActionResource]) -> bool:
	if starting_cards.is_empty():
		push_error(
			"ActionDeck: Starting cards is empty. Assign ActionResources to the starting deck."
		)
		return false

	for action_resource: ActionResource in starting_cards:
		if action_resource == null:
			push_error(
				"ActionDeck: Starting cards contains an empty slot."
			)
			return false

		if not action_resource.validate():
			return false

	cards = starting_cards.duplicate()

	return true


func start_round(hand_size: int) -> void:
	# Gathers every card (hand, draw pile, discard pile), shuffles, and draws
	# the opening hand.
	draw_pile = cards.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	resolving_card = null

	draw_cards(hand_size)


func draw_cards(count: int) -> int:
	# Returns how many cards were really drawn. Drawing from an empty deck is
	# normal gameplay, so running short is not an error.
	var drawn_count: int = 0

	for index: int in range(count):
		if draw_pile.is_empty():
			_reshuffle_discard_into_draw_pile()

		# Still empty: every other card is in the hand or being resolved.
		if draw_pile.is_empty():
			break

		hand.append(draw_pile.pop_back())
		drawn_count += 1

	return drawn_count


func begin_play(action_resource: ActionResource) -> bool:
	# Takes the card out of the hand while it resolves. The card goes to the
	# discard pile only in finish_play(), after all its effects are done.
	if resolving_card != null:
		push_warning(
			"ActionDeck: Cannot play a card while another is still resolving."
		)
		return false

	var hand_index: int = hand.find(action_resource)

	if hand_index == -1:
		push_warning(
			"ActionDeck: Cannot play a card that is not in the hand."
		)
		return false

	hand.remove_at(hand_index)
	resolving_card = action_resource

	return true


func finish_play() -> void:
	if resolving_card == null:
		push_warning("ActionDeck: finish_play() called with no card resolving.")
		return

	discard_pile.append(resolving_card)
	resolving_card = null


func _reshuffle_discard_into_draw_pile() -> void:
	# Cards still in the hand stay there. Only the discard pile is shuffled.
	if discard_pile.is_empty():
		return

	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()


func add_card(action_resource: ActionResource) -> void:
	# A card bought in the shop. It joins the deck for the rest of the run and
	# is dealt from the next round on.
	if action_resource == null or not action_resource.validate():
		push_error("ActionDeck: Cannot add an invalid ActionResource.")
		return

	cards.append(action_resource)
