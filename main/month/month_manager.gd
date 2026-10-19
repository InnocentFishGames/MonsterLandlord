class_name MonthManager
extends Node


# Initial target and the amount added after each successful month.
# The goal is compared with the rent of ALL the weeks added together.
# These numbers are placeholders until the balance pass.
@export var rent_goal: int = 400
@export var rent_goal_increase: int = 20
# The building is resolved this many times each month, once per week.
@export var weeks_per_month: int = 4

var current_month: int = 1


func initialize() -> bool:
	if rent_goal <= 0:
		push_error(
			"MonthManager: Rent goal must be greater than zero."
		)
		return false

	if weeks_per_month <= 0:
		push_error(
			"MonthManager: Weeks per month must be greater than zero."
		)
		return false

	# Zero is allowed when testing a fixed target.
	if rent_goal_increase < 0:
		push_error(
			"MonthManager: Rent goal increase cannot be negative."
		)
		return false

	return true


func is_goal_met(collected_rent: int) -> bool:
	return collected_rent >= rent_goal


func advance_month() -> void:
	current_month += 1
	rent_goal += rent_goal_increase
