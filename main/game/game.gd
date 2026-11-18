class_name Game
extends Node2D


# Major systems owned by this gameplay scene.
# Game is responsible for wiring these systems together.
@export var building: Building
@export var hud: HUD
@export var tenant_choice_ui: TenantChoiceUI
@export var shop_ui: ShopUI

# Starting values. Several of these are testing numbers that may change.
# Put the same TenantResource in the list more than once for more copies.
@export var starting_tenants: Array[TenantResource] = []
@export var starting_actions: Array[ActionResource] = []
@export var starting_hand_size: int = 5
@export var plays_per_round: int = 6

# The run. All placeholder numbers until the balance pass.
# The rent goal of round N is starting_goal + (N - 1) * goal_increase.
@export var total_rounds: int = 8
@export var starting_goal: int = 60
@export var goal_increase: int = 20
# Shop money given for passing a round.
@export var shop_money_per_round: int = 5

# What the shop can sell, and how many of each it offers per visit.
@export var shop_tenants: Array[TenantResource] = []
@export var shop_actions: Array[ActionResource] = []
@export var shop_bonuses: Array[PersistentBonus] = []
@export var shop_packs: Array[PackResource] = []
@export var shop_items: Array[ItemResource] = []
@export var shop_tenant_offers: int = 3
@export var shop_action_offers: int = 3
@export var shop_bonus_offers: int = 1
@export var shop_pack_offers: int = 2
@export var shop_item_offers: int = 2

# Runtime state for the run. Game creates these and passes amounts to the
# interface; the interface never touches them directly.
var tenant_bag: TenantBag = TenantBag.new()
var action_deck: ActionDeck = ActionDeck.new()
var round_state: RoundState = RoundState.new()
var run_state: RunState = RunState.new()
var shop_state: ShopState = ShopState.new()

# True from the moment a card is played until all its effects are done.
# Nothing else may start in that time.
var is_resolving: bool = false
# The context of the card being resolved. Player answers are passed to it.
var _active_context: ActionContext = null


func _ready() -> void:
	# Game validates references to the major systems it coordinates.
	if building == null:
		push_error(
			"Game: Building has not been assigned in the Inspector."
		)
		return

	if hud == null:
		push_error(
			"Game: HUD has not been assigned in the Inspector."
		)
		return

	if tenant_choice_ui == null:
		push_error(
			"Game: TenantChoiceUI has not been assigned in the Inspector."
		)
		return

	if shop_ui == null:
		push_error(
			"Game: ShopUI has not been assigned in the Inspector."
		)
		return

	if starting_hand_size < 0:
		push_error(
			"Game: Starting Hand Size cannot be negative."
		)
		return

	if shop_money_per_round < 0:
		push_error(
			"Game: Shop Money Per Round cannot be negative."
		)
		return

	# Each system validates its own configuration.
	# Stop startup immediately if any required system fails.
	if not building.initialize():
		return

	if not hud.initialize():
		return

	if not tenant_choice_ui.initialize():
		return

	if not shop_ui.initialize():
		return

	if not shop_state.setup(
		shop_tenants, shop_actions, shop_bonuses, shop_packs, shop_items
	):
		return

	if not _setup_run():
		return

	# Connect events before the first round starts.
	hud.action_card_selected.connect(_on_action_card_selected)
	hud.end_round_requested.connect(_on_end_round_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.item_selected.connect(_on_item_selected)

	shop_ui.offer_selected.connect(_on_shop_offer_selected)
	shop_ui.pack_choice_selected.connect(_on_pack_choice_selected)
	shop_ui.continue_requested.connect(_on_shop_continue_requested)

	tenant_choice_ui.tenant_chosen.connect(_on_tenant_chosen)
	building.building_view.cell_chosen.connect(_on_cell_chosen)

	round_state.plays_changed.connect(hud.set_plays)
	round_state.rent_changed.connect(hud.set_rent)

	# Any change to the board changes the projected rent.
	building.building_state.tenant_placed.connect(_on_board_changed)
	building.building_state.tenant_removed.connect(_on_board_changed)
	building.building_state.tenant_changed.connect(_on_board_changed)
	building.building_state.cleared.connect(_on_board_changed)
	round_state.round_ended.connect(_on_round_ended)

	# Begin gameplay only after configuration and connections succeed.
	_start_round()


func _setup_run() -> bool:
	# A fresh run: the starting roster, the starting deck, round 1, no
	# shop money. Anything bought in a previous run is gone.
	if not tenant_bag.setup(starting_tenants):
		return false

	if not action_deck.setup(starting_actions):
		return false

	return run_state.start_run(total_rounds, starting_goal, goal_increase)


func _start_round() -> void:
	# Cleanup: everyone leaves the building and returns to the bag, and all
	# action cards are gathered, shuffled, and dealt again. This happens at
	# the start of the next round, after the shop, so purchases are included.
	building.building_state.clear()
	tenant_bag.return_all_to_bag()
	action_deck.start_round(starting_hand_size)

	if not round_state.start_round(plays_per_round):
		return

	hud.set_prompt("")
	hud.set_round_active(true)
	_refresh_hud()

	# A hand with nothing playable on an empty building ends the round at once.
	if not _has_playable_card():
		hud.set_prompt("No playable cards left. The round ends.")
		round_state.end_round()


func _refresh_hud() -> void:
	# One place that gives the interface everything it displays.
	var check_context: ActionContext = _make_check_context()
	var playable_flags: Array[bool] = []

	for hand_card: ActionResource in action_deck.hand:
		playable_flags.append(hand_card.can_play(check_context))

	hud.set_hand(action_deck.hand, round_state.plays_remaining, playable_flags)

	var item_flags: Array[bool] = []

	for held_item: ItemResource in run_state.items:
		item_flags.append(held_item.can_use(check_context))

	hud.set_items(run_state.items, RunState.ITEM_SLOT_COUNT, item_flags)
	hud.set_bonuses(run_state.bonuses)
	hud.set_run_info(
		run_state.current_round,
		run_state.total_rounds,
		run_state.get_goal(),
		run_state.shop_money
	)

	hud.set_pile_counts(
		tenant_bag.get_bag_size(),
		tenant_bag.get_discard_size(),
		action_deck.draw_pile.size(),
		action_deck.discard_pile.size()
	)


func _on_action_card_selected(action_resource: ActionResource) -> void:
	# A stale click (a round that ended, or a card already resolving)
	# is ignored.
	if is_resolving:
		return

	if not round_state.can_afford_play(action_resource.play_cost):
		return

	# A card with no legal target cannot be played. The HUD shows it in red;
	# this check covers a stale click.
	if not action_resource.can_play(_make_check_context()):
		return

	if not action_deck.begin_play(action_resource):
		return

	round_state.spend_plays(action_resource.play_cost)

	is_resolving = true
	hud.set_locked(true)

	# The whole card, including anything that waits for the player, must
	# finish before the card is discarded.
	await _resolve_effects(
		action_resource.effects,
		[GameEvent.new(GameEvent.Trigger.ACTION_PLAYED)]
	)

	is_resolving = false
	hud.set_locked(false)

	# Only now does the card reach the discard pile.
	action_deck.finish_play()

	if round_state.plays_remaining <= 0:
		round_state.end_round()
		return

	# The free replacement draw. Drawing never costs a play.
	action_deck.draw_cards(1)

	# Nothing in the hand can be played (no legal targets, or too costly).
	# Nothing can change that, so the round ends.
	if not _has_playable_card():
		hud.set_prompt("No playable cards left. The round ends.")
		round_state.end_round()
		return

	_refresh_hud()


func _resolve_effects(
	effects: Array[ActionEffect],
	starting_events: Array[GameEvent]
) -> void:
	var context: ActionContext = ActionContext.new(
		tenant_bag,
		building.building_state,
		run_state
	)

	# When an effect needs the player, show the matching interface.
	context.tenant_choice_requested.connect(_on_tenant_choice_requested)
	context.cell_choice_requested.connect(_on_cell_choice_requested)

	_active_context = context

	for action_effect: ActionEffect in effects:
		# Some effects wait for the player and some finish at once. The
		# base class cannot say which, so the "unneeded await" warning is
		# expected here.
		@warning_ignore("redundant_await")
		await action_effect.execute(context)

	_active_context = null

	# The effects are done and every change stands on the board. Now tenants
	# react, as one chain, in top-left to bottom-right order. A card starts
	# its chain with ACTION_PLAYED; an item has no starting event.
	var chain_events: Array[GameEvent] = starting_events.duplicate()
	chain_events.append_array(context.events)
	_resolve_chain(chain_events)


func _on_item_selected(slot_index: int) -> void:
	# Items can be used between cards while a round is running. Stale clicks
	# (a card resolving, the round over, an empty slot) are ignored.
	if is_resolving or not round_state.is_active:
		return

	if slot_index < 0 or slot_index >= run_state.items.size():
		return

	var item: ItemResource = run_state.items[slot_index]

	# An item with nothing to act on is shown in red and cannot be used.
	if not item.can_use(_make_check_context()):
		return

	# The item is spent as soon as it is used, like a card's play cost.
	run_state.remove_item(slot_index)

	is_resolving = true
	hud.set_locked(true)

	await _resolve_effects(item.effects, [])

	is_resolving = false
	hud.set_locked(false)
	_refresh_hud()


func _on_tenant_choice_requested(
	options: Array[TenantInstance]
) -> void:
	tenant_choice_ui.show_choices(options)
	hud.set_prompt("Choose a tenant to place.")


func _on_tenant_chosen(tenant_instance: TenantInstance) -> void:
	hud.set_prompt("")

	if _active_context != null:
		_active_context.submit_tenant_choice(tenant_instance)


func _on_cell_choice_requested(
	valid_positions: Array[Vector2i],
	prompt: String
) -> void:
	building.building_view.begin_cell_choice(valid_positions)
	hud.set_prompt(prompt)


func _on_cell_chosen(grid_position: Vector2i) -> void:
	hud.set_prompt("")

	if _active_context != null:
		_active_context.submit_cell_choice(grid_position)


func _on_end_round_requested() -> void:
	# Pending effects finish first. The button is disabled while a card
	# resolves; this check covers a stale click.
	if is_resolving:
		return

	round_state.end_round()


func _on_round_ended() -> void:
	# 1. Round-end abilities pay the rent.
	_resolve_chain([GameEvent.new(GameEvent.Trigger.ROUND_END)])
	hud.set_round_active(false)
	_refresh_hud()

	# 2. Payment check. Missing the goal ends the run.
	var rent_goal: int = run_state.get_goal()

	if round_state.rent_total < rent_goal:
		hud.show_run_over(
			"Run over. Rent $%d did not reach the goal of $%d."
			% [round_state.rent_total, rent_goal]
		)
		return

	run_state.add_shop_money(shop_money_per_round)
	_refresh_hud()

	if run_state.is_final_round():
		hud.show_run_over(
			"You won! You paid the rent in all %d rounds."
			% run_state.total_rounds
		)
		return

	# 3. Cleanup happens when the next round starts. 4. The shop.
	hud.set_prompt(
		"Goal reached! +$%d shop money." % shop_money_per_round
	)
	shop_state.roll_offers(
		shop_tenant_offers,
		shop_action_offers,
		shop_bonus_offers,
		shop_pack_offers,
		shop_item_offers,
		run_state.bonuses
	)
	shop_ui.show_shop(
		shop_state.offers,
		run_state.shop_money,
		not run_state.has_free_item_slot()
	)


func _on_shop_offer_selected(offer: ShopOffer) -> void:
	if not shop_state.try_buy(offer, run_state, tenant_bag, action_deck):
		return

	_refresh_hud()

	if offer.kind == ShopOffer.Kind.PACK:
		# The pack is paid for. The player must pick one item before the
		# shop continues.
		shop_ui.show_pack_choices(shop_state.roll_pack_choices(offer))
	else:
		shop_ui.refresh(
			shop_state.offers,
			run_state.shop_money,
			not run_state.has_free_item_slot()
		)


func _on_pack_choice_selected(choice: ShopOffer) -> void:
	shop_state.take_pack_choice(choice, tenant_bag, action_deck)
	shop_ui.refresh(
		shop_state.offers,
		run_state.shop_money,
		not run_state.has_free_item_slot()
	)
	_refresh_hud()


func _on_shop_continue_requested() -> void:
	shop_ui.hide_shop()
	run_state.advance_round()
	_start_round()


func _on_restart_requested() -> void:
	if not _setup_run():
		return

	hud.hide_run_over()
	_start_round()


func _resolve_chain(starting_events: Array[GameEvent]) -> void:
	# One chain = one ChainResolver run with a fresh ability context.
	var ability_context: AbilityContext = AbilityContext.new(
		building.building_state,
		round_state,
		run_state.bonuses
	)
	var chain_resolver: ChainResolver = ChainResolver.new()

	chain_resolver.resolve(starting_events, ability_context)


func _on_board_changed(
	_grid_position: Vector2i = Vector2i.ZERO,
	_tenant_instance: TenantInstance = null
) -> void:
	# Preview: run the round-end chain on a throwaway RoundState. The real
	# round's rent and log are untouched; only the total is shown.
	var scratch_round: RoundState = RoundState.new()
	var scratch_context: AbilityContext = AbilityContext.new(
		building.building_state,
		scratch_round,
		run_state.bonuses
	)

	ChainResolver.new().resolve(
		[GameEvent.new(GameEvent.Trigger.ROUND_END)],
		scratch_context
	)

	hud.set_projected_rent(scratch_round.rent_total, run_state.get_goal())


func _make_check_context() -> ActionContext:
	# A throwaway context used only to ask "could this card do anything?".
	return ActionContext.new(tenant_bag, building.building_state, run_state)


func _has_playable_card() -> bool:
	var check_context: ActionContext = _make_check_context()

	for hand_card: ActionResource in action_deck.hand:
		if (
			round_state.can_afford_play(hand_card.play_cost)
			and hand_card.can_play(check_context)
		):
			return true

	return false
