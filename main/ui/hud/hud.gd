class_name HUD
extends CanvasLayer


# The player clicked a card in their hand. Game decides what that means.
signal action_card_selected(action_resource: ActionResource)
# The player chose to stop playing actions and end the round.
signal end_round_requested()
# The run ended (won or lost) and the player wants to try again.
signal restart_requested()


# Round number, rent goal and shop money.
@export var run_label: Label
# The persistent bonuses the player owns.
@export var bonuses_label: Label
@export var plays_label: Label
@export var rent_label: Label
# What the rent would be if the round ended right now.
@export var projected_rent_label: Label
# One line per rent payment, so the player sees where the money came from.
@export var rent_log_label: Label
@export var pile_counts_label: Label
# Tells the player what to do next, e.g. "Click a highlighted cell".
@export var prompt_label: Label
# Holds one button per card in the hand. Rebuilt whenever the hand changes.
@export var hand_container: VBoxContainer
@export var end_round_button: Button
@export var restart_button: Button

var _is_round_active: bool = false
var _is_locked: bool = false
var _is_run_over: bool = false


func initialize() -> bool:
	if run_label == null:
		push_error("HUD: Run Label has not been assigned.")
		return false

	if bonuses_label == null:
		push_error("HUD: Bonuses Label has not been assigned.")
		return false

	if plays_label == null:
		push_error("HUD: Plays Label has not been assigned.")
		return false

	if rent_label == null:
		push_error("HUD: Rent Label has not been assigned.")
		return false

	if projected_rent_label == null:
		push_error("HUD: Projected Rent Label has not been assigned.")
		return false

	if rent_log_label == null:
		push_error("HUD: Rent Log Label has not been assigned.")
		return false

	if pile_counts_label == null:
		push_error("HUD: Pile Counts Label has not been assigned.")
		return false

	if prompt_label == null:
		push_error("HUD: Prompt Label has not been assigned.")
		return false

	if hand_container == null:
		push_error("HUD: Hand Container has not been assigned.")
		return false

	if end_round_button == null:
		push_error("HUD: End Round Button has not been assigned.")
		return false

	if restart_button == null:
		push_error("HUD: Restart Button has not been assigned.")
		return false

	end_round_button.pressed.connect(_on_end_round_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)

	prompt_label.text = ""
	_update_controls()

	return true


func set_plays(plays_remaining: int) -> void:
	plays_label.text = "Plays left: %d" % plays_remaining


func set_pile_counts(
	bag_count: int,
	tenant_discard_count: int,
	draw_pile_count: int,
	action_discard_count: int
) -> void:
	pile_counts_label.text = (
		"Tenant bag: %d  |  Tenant discard: %d\n"
		+ "Draw pile: %d  |  Action discard: %d"
	) % [
		bag_count,
		tenant_discard_count,
		draw_pile_count,
		action_discard_count
	]


func set_hand(
	hand: Array[ActionResource],
	plays_remaining: int,
	playable_flags: Array[bool]
) -> void:
	# Rebuilds the cards each time, so a played card simply disappears.
	for child: Node in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()

	for hand_index: int in range(hand.size()):
		var action_resource: ActionResource = hand[hand_index]

		# Placeholder card: a plain button until the final art exists.
		var card_button: Button = Button.new()
		card_button.custom_minimum_size = Vector2(0, 90)
		card_button.text = (
			"%s  (costs %d)\n%s"
			% [
				action_resource.action_name,
				action_resource.play_cost,
				action_resource.description
			]
		)
		# Cards that cost more plays than remain are visible but not playable.
		card_button.disabled = action_resource.play_cost > plays_remaining

		# Cards with no legal target are red and cannot be clicked.
		if not playable_flags[hand_index]:
			card_button.disabled = true
			card_button.modulate = Color(1.0, 0.45, 0.45)
			card_button.text += "\n(no legal target)"

		card_button.pressed.connect(
			_on_card_button_pressed.bind(action_resource)
		)

		hand_container.add_child(card_button)


func set_round_active(is_active: bool) -> void:
	_is_round_active = is_active
	_update_controls()


func set_locked(is_locked: bool) -> void:
	# While a card resolves, the hand is hidden and the round cannot be
	# ended, so nothing else can start before the card is finished.
	_is_locked = is_locked
	_update_controls()


func set_prompt(text: String) -> void:
	prompt_label.text = text


func _update_controls() -> void:
	# While the round runs the player can play cards or end it. When the run
	# is over they can only start a new one.
	hand_container.visible = _is_round_active and not _is_locked
	end_round_button.visible = _is_round_active
	end_round_button.disabled = _is_locked
	restart_button.visible = _is_run_over


func _on_card_button_pressed(action_resource: ActionResource) -> void:
	action_card_selected.emit(action_resource)


func _on_end_round_button_pressed() -> void:
	end_round_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func set_rent(rent_total: int, rent_log: Array[String]) -> void:
	rent_label.text = "Rent: $%d" % rent_total
	rent_log_label.text = "\n".join(rent_log)


func set_projected_rent(projected_rent: int, rent_goal: int) -> void:
	projected_rent_label.text = (
		"Projected rent: $%d / goal $%d" % [projected_rent, rent_goal]
	)


func set_run_info(
	current_round: int,
	total_rounds: int,
	rent_goal: int,
	shop_money: int
) -> void:
	run_label.text = "Round %d / %d  |  Goal $%d  |  Shop money $%d" % [
		current_round, total_rounds, rent_goal, shop_money
	]


func show_run_over(message: String) -> void:
	# The run is finished. Only the Start New Run button remains.
	_is_run_over = true
	prompt_label.text = message
	_update_controls()


func hide_run_over() -> void:
	_is_run_over = false
	_update_controls()


func set_bonuses(bonuses: Array[PersistentBonus]) -> void:
	if bonuses.is_empty():
		bonuses_label.text = ""
		return

	var names: Array[String] = []

	for bonus: PersistentBonus in bonuses:
		names.append(bonus.bonus_name)

	bonuses_label.text = "Bonuses: " + ", ".join(names)
