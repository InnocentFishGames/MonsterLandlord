class_name RunState
extends RefCounted


# Everything that lasts across rounds within one run: which round it is, how
# high the rent goal is, and the player's shop money (a separate currency
# from rent). Game creates this once and passes amounts to the interface.

var current_round: int = 1
var total_rounds: int = 8
var starting_goal: int = 60
var goal_increase: int = 20
var shop_money: int = 0
# Bonuses bought this run, in the order they were bought.
var bonuses: Array[PersistentBonus] = []


func start_run(
	new_total_rounds: int,
	new_starting_goal: int,
	new_goal_increase: int
) -> bool:
	if new_total_rounds <= 0:
		push_error("RunState: A run needs at least one round.")
		return false

	if new_starting_goal <= 0:
		push_error("RunState: Starting goal must be greater than zero.")
		return false

	# Zero is allowed when testing a fixed goal.
	if new_goal_increase < 0:
		push_error("RunState: Goal increase cannot be negative.")
		return false

	total_rounds = new_total_rounds
	starting_goal = new_starting_goal
	goal_increase = new_goal_increase
	current_round = 1
	shop_money = 0
	bonuses.clear()

	return true


func get_goal() -> int:
	# The rent the building must earn this round to pass.
	return starting_goal + (current_round - 1) * goal_increase


func is_final_round() -> bool:
	return current_round >= total_rounds


func advance_round() -> void:
	current_round += 1


func add_shop_money(amount: int) -> void:
	if amount < 0:
		push_warning(
			"RunState: add_shop_money() received a negative amount. Use try_spend_shop_money()."
		)
		return

	shop_money += amount


func try_spend_shop_money(price: int) -> bool:
	# Not being able to afford something is normal gameplay, not an error.
	if price < 0 or shop_money < price:
		return false

	shop_money -= price

	return true


func add_bonus(bonus: PersistentBonus) -> void:
	if bonus == null:
		push_error("RunState: Cannot add a null PersistentBonus.")
		return

	bonuses.append(bonus)
