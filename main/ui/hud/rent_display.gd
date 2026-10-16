class_name RentDisplay
extends VBoxContainer


@export var monthly_goal_label: Label
@export var projected_rent_label: Label
@export var month_result_label: Label


func initialize() -> bool:
	# Validate the labels assigned in the Inspector.
	if monthly_goal_label == null:
		push_error(
			"RentDisplay: Monthly Goal Label has not been assigned."
		)
		return false

	if projected_rent_label == null:
		push_error(
			"RentDisplay: Projected Rent Label has not been assigned."
		)
		return false

	if month_result_label == null:
		push_error(
			"RentDisplay: Month Result Label has not been assigned."
		)
		return false

	# No result should appear before the month finishes.
	month_result_label.text = ""

	return true


func set_monthly_goal(month_number: int, amount: int) -> void:
	# Show both the current month and its requirement.
	monthly_goal_label.text = (
		"Month %d — Goal: $%d"
		% [month_number, amount]
	)

func set_projected_rent(amount: int) -> void:
	projected_rent_label.text = "Projected Rent: $" + str(amount)


func show_month_result(
	goal_met: bool,
	collected_rent: int,
	rent_goal: int
) -> void:
	# Game supplies the outcome. This display only formats it.
	var result_text: String = "Month failed"

	if goal_met:
		result_text = "Month passed"

	month_result_label.text = (
		"%s — Collected: $%d / Goal: $%d"
		% [result_text, collected_rent, rent_goal]
	)


func clear_month_result() -> void:
	# The previous result no longer applies to the new month.
	month_result_label.text = ""
