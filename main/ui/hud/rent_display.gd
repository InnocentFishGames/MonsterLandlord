class_name RentDisplay
extends VBoxContainer


@export var monthly_goal_label: Label
@export var projected_rent_label: Label
@export var month_result_label: Label
@export var resolution_log_label: Label
@export var draft_round_label: Label
@export var cash_label: Label


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

	if resolution_log_label == null:
		push_error(
			"RentDisplay: Resolution Log Label has not been assigned."
		)
		return false

	if draft_round_label == null:
		push_error(
			"RentDisplay: Draft Round Label has not been assigned."
		)
		return false

	if cash_label == null:
		push_error(
			"RentDisplay: Cash Label has not been assigned."
		)
		return false

	# No result should appear before the month finishes.
	month_result_label.text = ""
	resolution_log_label.text = ""
	draft_round_label.text = ""

	return true


func set_monthly_goal(month_number: int, amount: int) -> void:
	# Show both the current month and its requirement.
	monthly_goal_label.text = (
		"Month %d — Goal: $%d"
		% [month_number, amount]
	)


func set_draft_round(current_round: int, total_rounds: int) -> void:
	draft_round_label.text = (
		"Draft round %d of %d"
		% [current_round, total_rounds]
	)


func clear_draft_round() -> void:
	# Drafting is over for this month.
	draft_round_label.text = ""


func set_projected_rent(weekly_rent: int, monthly_rent: int) -> void:
	# The goal is compared with the whole month, so show both numbers.
	projected_rent_label.text = (
		"Projected Rent: $%d / week ($%d / month)"
		% [weekly_rent, monthly_rent]
	)


func show_month_result(
	goal_met: bool,
	collected_rent: int,
	rent_goal: int,
	week_totals: Array[int],
	cash_earned: int
) -> void:
	# Game supplies the outcome. This display only formats it.
	var result_text: String = "Month failed"

	if goal_met:
		result_text = "Month passed"

	# Show each week's rent so the player can see how the total was made.
	var week_texts: Array[String] = []

	for week_total: int in week_totals:
		week_texts.append("$%d" % week_total)

	month_result_label.text = (
		"%s — Collected: $%d / Goal: $%d\nWeeks: %s"
		% [
			result_text,
			collected_rent,
			rent_goal,
			" + ".join(week_texts)
		]
	)

	# Only a passed month earns cash.
	if goal_met:
		month_result_label.text += "\nCash earned: $%d" % cash_earned


func show_resolution_log(week_results: Array[RentResult]) -> void:
	# DEBUG: a plain-text log for checking resolution order while building
	# the game. It may not appear in the final UI.
	# One heading per week, then one line per room in resolution order.
	var lines: Array[String] = []

	for week_index: int in range(week_results.size()):
		var week_result: RentResult = week_results[week_index]

		lines.append(
			"Week %d: $%d"
			% [week_index + 1, week_result.total_rent]
		)

		for entry_index: int in range(week_result.entries.size()):
			var entry: RentEntry = week_result.entries[entry_index]

			lines.append(
				"  %d. Room (%d, %d) %s: $%d"
				% [
					entry_index + 1,
					entry.grid_position.x,
					entry.grid_position.y,
					entry.tenant_name,
					entry.rent
				]
			)

	resolution_log_label.text = "\n".join(lines)


func clear_month_result() -> void:
	# The previous result no longer applies to the new month.
	month_result_label.text = ""
	resolution_log_label.text = ""


func set_cash(amount: int) -> void:
	cash_label.text = "Cash: $%d" % amount
