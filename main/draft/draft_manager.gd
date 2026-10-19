class_name DraftManager
extends Node


# The TenantResources currently allowed to appear in a draft.
@export var available_tenants: Array[TenantResource] = []
@export var draft_ui: DraftUI
# How many draft rounds a month offers. The player may skip any round, or
# skip all the rounds that are left.
@export var rounds_per_month: int = 6


const DRAFT_CHOICE_COUNT: int = 3


# How many rounds have been offered so far this month.
var rounds_offered: int = 0


func initialize() -> bool:
	# Game calls this before starting the first draft.
	# Return false if Inspector configuration prevents drafting.
	if rounds_per_month <= 0:
		push_error(
			"DraftManager: Rounds Per Month must be greater than zero."
		)
		return false

	if draft_ui == null:
		push_error(
			"DraftManager: DraftUI has not been assigned in the Inspector."
		)
		return false

	if available_tenants.size() < DRAFT_CHOICE_COUNT:
		push_error(
			"DraftManager: At least %d TenantResources are required to create a draft."
			% DRAFT_CHOICE_COUNT
		)
		return false

	for tenant_resource: TenantResource in available_tenants:
		if tenant_resource == null:
			push_error(
				"DraftManager: Available Tenants contains an empty TenantResource slot."
			)
			return false

		# Validate each definition before allowing it into the draft pool.
		if not tenant_resource.validate():
			return false
	# Drafting also requires a correctly configured interface.
	# DraftUI validates its own dependencies and reports any error.
	if not draft_ui.initialize():
		return false

	# All configuration owned by DraftManager is valid.
	return true


func start_month() -> void:
	# A new month offers its full set of rounds again.
	rounds_offered = 0


func has_rounds_left() -> bool:
	return rounds_offered < rounds_per_month


func offer_next_draft() -> bool:
	# Uses up one of the month's rounds, whether or not the player
	# picks a tenant from it.
	if not has_rounds_left():
		push_warning(
			"DraftManager: No draft rounds are left this month."
		)
		return false

	rounds_offered += 1

	return create_draft()


func create_draft() -> bool:
	var draft_pool: Array[TenantResource] = (
		available_tenants.duplicate()
	)

	var choices: Array[TenantResource] = []

	for index: int in range(DRAFT_CHOICE_COUNT):
		var random_index: int = randi_range(
			0,
			draft_pool.size() - 1
		)

		var tenant_resource: TenantResource = (
			draft_pool[random_index]
		)

		choices.append(tenant_resource)

		# Prevent the same TenantResource from appearing
		# more than once in this draft.
		draft_pool.remove_at(random_index)

	return draft_ui.show_draft(choices)

func close_draft() -> void:
	draft_ui.clear_draft()
