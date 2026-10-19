class_name Game
extends Node2D


# Major systems owned by this gameplay scene.
# Game is responsible for wiring these systems together.
@export var building: Building
@export var placement_controller: PlacementController
@export var draft_manager: DraftManager
@export var resolution_manager: ResolutionManager
@export var hud: HUD
@export var month_manager: MonthManager

@export var shop_manager: ShopManager
@export var shop_ui: ShopUI
# Temporary test scaffolding: the rooms created at game start, left to
# right along the top row. Swap entries in the Inspector to try other rooms.
@export var starting_rooms: Array[RoomResource] = []

# The player's cash. Game owns it and passes amounts to the interface.
var wallet: Wallet = Wallet.new()
# The rooms the shop currently offers. A bought room is removed from here.
var current_offers: Array[RoomResource] = []
# The room being placed after the player chose to buy it. It is only paid for
# once the placement is confirmed.
var pending_purchase: RoomResource = null


func _ready() -> void:
	# Game validates references to the major systems it coordinates.
	if building == null:
		push_error(
			"Game: Building has not been assigned in the Inspector."
		)
		return

	if hud == null:
		push_error(
			"Game: HUD has not been assigned."
		)
		return

	if placement_controller == null:
		push_error(
			"Game: PlacementController has not been assigned in the Inspector."
		)
		return

	if draft_manager == null:
		push_error(
			"Game: DraftManager has not been assigned in the Inspector."
		)
		return

	if resolution_manager == null:
		push_error(
			"Game: ResolutionManager has not been assigned."
		)
		return
	
	if month_manager == null:
		push_error(
			"Game: MonthManager has not been assigned."
		)
		return

	if shop_manager == null:
		push_error(
			"Game: ShopManager has not been assigned in the Inspector."
		)
		return

	if shop_ui == null:
		push_error(
			"Game: ShopUI has not been assigned in the Inspector."
		)
		return

	# Each system validates its own configuration.
	# Stop startup immediately if any required system fails.
	if not building.initialize():
		return

	if not hud.initialize():
		return

	if not draft_manager.initialize():
		return

	if not month_manager.initialize():
		return

	if not shop_manager.initialize():
		return

	if not shop_ui.initialize():
		return

	# Building's components are now initialized and safe to supply
	# as dependencies to the placement controller.
	if not placement_controller.setup(
		building.grid_component,
		building.room_container
	):
		return

	# Connect gameplay events before creating rooms or starting drafts.
	placement_controller.placement_confirmed.connect(
		_on_placement_confirmed
	)

	building.room_container.tenant_assigned.connect(
		_on_tenant_assigned
	)

	building.room_container.room_added.connect(
		_on_room_added
	)

	draft_manager.draft_ui.tenant_drag_released.connect(
		_on_tenant_drag_released
	)
	
	hud.open_shop_requested.connect(
		_on_open_shop_requested
	)

	hud.restart_requested.connect(
		_on_restart_requested
	)

	shop_ui.offer_selected.connect(
		_on_shop_offer_selected
	)

	shop_ui.continue_requested.connect(
		_on_shop_continue_requested
	)

	shop_ui.placement_back_requested.connect(
		_on_shop_placement_back_requested
	)

	wallet.cash_changed.connect(
		_on_cash_changed
	)

	hud.skip_draft_requested.connect(
		_on_skip_draft_requested
	)

	hud.collect_rent_requested.connect(
		_on_collect_rent_requested
	)

	placement_controller.placement_cancelled.connect(
		_on_placement_cancelled
	)

	# Begin gameplay only after configuration and connections succeed.
	if not _create_test_rooms():
		return

	hud.rent_display.set_monthly_goal(
		month_manager.current_month,
		month_manager.rent_goal
	)

	hud.rent_display.set_cash(wallet.cash)

	_clear_rent_preview()

	draft_manager.start_month()
	_continue_month()


func _create_test_rooms() -> bool:
	var starting_positions: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0)
	]

	if starting_rooms.size() != starting_positions.size():
		push_error(
			"Game: Starting Rooms needs exactly %d RoomResources."
			% starting_positions.size()
		)
		return false

	for index: int in range(starting_positions.size()):
		var grid_position: Vector2i = starting_positions[index]

		var room_instance: RoomInstance = RoomInstance.new(
			starting_rooms[index],
			grid_position
		)

		var was_added: bool = building.room_container.add_room(
			room_instance
		)

		if not was_added:
			# Include the failed position to help locate the problem.
			# Stop immediately instead of attempting the remaining rooms.
			push_error(
				"Game: Failed to create starting room at %s."
				% grid_position
			)
			return false

	# Every starting room was added successfully.
	return true


func _on_tenant_assigned(
	_tenant_instance: TenantInstance
) -> void:
	_continue_month()


func _continue_month() -> void:
	# Shared by tenant placement, skipped rounds, and the start of a month.
	# The month goes on to rent collection when the building is full (no
	# vacancies left) or when every draft round has been offered.
	# Otherwise the next draft round is offered.
	if (
		building.room_container.is_full()
		or not draft_manager.has_rounds_left()
	):
		_finish_month()
		return

	if not draft_manager.offer_next_draft():
		return

	hud.rent_display.set_draft_round(
		draft_manager.rounds_offered,
		draft_manager.rounds_per_month
	)


func _on_skip_draft_requested() -> void:
	# Skipping uses up the current round without picking a tenant.
	_continue_month()


func _on_collect_rent_requested() -> void:
	# Ends drafting early. Any rounds that are left are skipped.
	_finish_month()


func _finish_month() -> void:
	# Normal placement, skipped rounds, and an already-full building can
	# all complete a month using this shared operation.
	draft_manager.close_draft()
	hud.set_draft_controls_available(false)
	hud.rent_display.clear_draft_round()

	# Each week is a fresh resolution. The weeks are added together and
	# compared with the month's goal once.
	var week_results: Array[RentResult] = (
		resolution_manager.resolve_weeks(
			building.room_container,
			month_manager.weeks_per_month
		)
	)

	var week_totals: Array[int] = []
	var month_rent: int = 0

	for week_result: RentResult in week_results:
		week_totals.append(week_result.total_rent)
		month_rent += week_result.total_rent

	var goal_met: bool = month_manager.is_goal_met(month_rent)

	# Surplus rent, the pass bonus, and rounds the player did not use are
	# turned into cash. A failed month earns nothing.
	var unused_rounds: int = (
		draft_manager.rounds_per_month - draft_manager.rounds_offered
	)
	var cash_earned: int = month_manager.calculate_cash_earned(
		month_rent,
		unused_rounds
	)
	wallet.add_cash(cash_earned)

	_clear_rent_preview()

	hud.rent_display.show_month_result(
		goal_met,
		month_rent,
		month_manager.rent_goal,
		week_totals,
		cash_earned
	)

	# DEBUG: remove this line (and ResolutionLogLabel in hud.tscn) to hide
	# the log. Nothing else depends on it.
	hud.rent_display.show_resolution_log(week_results)

	# Passing opens the shop; failing offers a fresh run.
	hud.set_open_shop_available(goal_met)
	hud.set_restart_available(not goal_met)


func _on_cash_changed(new_amount: int) -> void:
	hud.rent_display.set_cash(new_amount)


func _on_open_shop_requested() -> void:
	hud.set_open_shop_available(false)

	current_offers = shop_manager.create_offers()
	shop_ui.show_shop(current_offers, wallet.cash)


func _on_shop_offer_selected(room_resource: RoomResource) -> void:
	# The card is disabled when unaffordable, but check anyway so a stale
	# click can never create a free room.
	if not wallet.can_afford(room_resource.price):
		return

	# Nothing is paid yet. The cost is taken when the placement is confirmed,
	# so cancelling needs no refund.
	if not placement_controller.start_placement(room_resource):
		return

	pending_purchase = room_resource
	shop_ui.show_placement(room_resource)


func _on_shop_placement_back_requested() -> void:
	# Works before the room has been dropped on the grid.
	placement_controller.cancel_placement()


func _on_placement_cancelled() -> void:
	pending_purchase = null
	shop_ui.show_shop(current_offers, wallet.cash)


func _on_placement_confirmed(
	room_instance: RoomInstance
) -> void:

	var was_added: bool = building.room_container.add_room(
		room_instance
	)

	if not was_added:
		push_error(
			"Game: RoomManager failed to add the confirmed room."
		)
		return

	# Affordability was checked when the offer was chosen, and cash cannot
	# change during placement, so this should always succeed.
	if not wallet.try_spend(pending_purchase.price):
		push_error(
			"Game: Could not pay for the placed room. Cash changed during placement."
		)

	current_offers.erase(pending_purchase)
	pending_purchase = null

	placement_controller.finish_placement()
	# The new room is empty, so projected rent may change once tenants move.
	_clear_rent_preview()

	shop_ui.show_shop(current_offers, wallet.cash)


func _on_tenant_hovered(
	room_instance: RoomInstance,
	tenant_resource: TenantResource
) -> void:
	# Godot may call _can_drop_data() repeatedly while a drag stays over
	# one room, so this runs often. The calculation is cheap, so we simply
	# recalculate each time instead of caching the last hover.
	# TenantDropArea only reports hovers for empty rooms.
	var projected_result: RentResult = (
		resolution_manager.calculate_projected_rent(
			building.room_container,
			room_instance,
			tenant_resource
		)
	)

	_show_projected_rent(projected_result.total_rent)


func _on_tenant_drag_released() -> void:
	# Recalculate even if no preview is active.
	# A successful drop may have changed actual building rent.
	_clear_rent_preview()


func _on_room_added(room: Room) -> void:
	room.tenant_hovered.connect(
		_on_tenant_hovered
	)

	room.tenant_hover_ended.connect(
		_on_tenant_hover_ended
	)


func _on_tenant_hover_ended(_room_instance: RoomInstance) -> void:
	# The pointer left a room, so show the real rent again.
	# If it moved onto another room, that room's next hover event
	# immediately replaces this with its own projection.
	_clear_rent_preview()


func _clear_rent_preview() -> void:
	# Calculate rent using only tenants actually assigned to rooms.
	var current_result: RentResult = (
		resolution_manager.resolve_building(
			building.room_container
		)
	)

	_show_projected_rent(current_result.total_rent)


func _show_projected_rent(weekly_rent: int) -> void:
	# For now every week is the same, so a month is the weekly rent times
	# the number of weeks. Once events can change a single week, this is
	# only an estimate.
	hud.rent_display.set_projected_rent(
		weekly_rent,
		weekly_rent * month_manager.weeks_per_month
	)


func _on_shop_continue_requested() -> void:
	# Leaving the shop starts the next month.
	shop_ui.hide_shop()
	current_offers.clear()

	# Rooms remain. Only non-permanent tenants leave.
	building.room_container.remove_temporary_tenants()

	month_manager.advance_month()

	hud.rent_display.clear_month_result()
	
	hud.rent_display.set_monthly_goal(
		month_manager.current_month,
		month_manager.rent_goal
	)

	hud.set_draft_controls_available(true)

	# Clear any cached preview and display rent from tenants who stayed.
	_clear_rent_preview()

	# A new month offers a full set of draft rounds again.
	draft_manager.start_month()

	# If every room contains a permanent tenant, this resolves the
	# month immediately instead of drafting.
	_continue_month()


func _on_restart_requested() -> void:
	# Reload the current scene to rebuild the run from its saved
	# Inspector configuration. Runtime month and tenant state reset.
	var reload_error: Error = get_tree().reload_current_scene()

	if reload_error != OK:
		push_error(
			"Game: Could not restart the current scene. Error code: %d."
			% reload_error
		)
