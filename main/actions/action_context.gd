class_name ActionContext
extends RefCounted


# Everything an action's effects are allowed to do while one card resolves.
# Game creates one per card play and throws it away afterwards.
#
# Effects never touch the interface. When an effect needs the player to
# decide something, it awaits choose_tenant() or choose_cell(). Those emit a
# "requested" signal that Game shows on screen, and wait until Game hands
# the answer back through submit_tenant_choice() / submit_cell_choice().
# Answers must arrive after the request, for example from a button click.


# The player must pick one of these tenants.
signal tenant_choice_requested(options: Array[TenantInstance])
# The player must pick one of these cells. `prompt` tells them why.
signal cell_choice_requested(
	valid_positions: Array[Vector2i],
	prompt: String
)

signal _tenant_choice_submitted(tenant_instance: TenantInstance)
signal _cell_choice_submitted(grid_position: Vector2i)


var tenant_bag: TenantBag
var building_state: BuildingState

# Everything that happened during this card, in order. Game hands these to
# the ChainResolver once the card is done.
var events: Array[GameEvent] = []

# What the player is currently allowed to answer. Empty means "no question
# is open", so a stray answer is ignored.
var _pending_tenant_options: Array[TenantInstance] = []
var _pending_valid_positions: Array[Vector2i] = []


func _init(
	new_tenant_bag: TenantBag,
	new_building_state: BuildingState
) -> void:
	tenant_bag = new_tenant_bag
	building_state = new_building_state


func draw_tenants(count: int) -> Array[TenantInstance]:
	# Draws up to `count` tenants. An empty bag just means fewer tenants
	# (possibly none). That is normal gameplay, not an error.
	var drawn_tenants: Array[TenantInstance] = []

	for index: int in range(count):
		var drawn_tenant: TenantInstance = tenant_bag.draw_random()

		if drawn_tenant == null:
			break

		drawn_tenants.append(drawn_tenant)

	return drawn_tenants


func discard_tenants(tenants: Array[TenantInstance]) -> void:
	for tenant_instance: TenantInstance in tenants:
		tenant_bag.discard(tenant_instance)


func get_empty_positions() -> Array[Vector2i]:
	return building_state.get_empty_positions()


func place_tenant(
	grid_position: Vector2i,
	tenant_instance: TenantInstance,
	placement_trigger: GameEvent.Trigger
) -> bool:
	if not building_state.place_tenant(grid_position, tenant_instance):
		return false

	# Only remember the placement. Abilities react after the whole card has
	# finished, so tenants that arrive together all stand on the board first.
	events.append(
		GameEvent.new(placement_trigger, tenant_instance, grid_position)
	)

	return true


func choose_tenant(
	options: Array[TenantInstance]
) -> TenantInstance:
	_pending_tenant_options = options.duplicate()
	tenant_choice_requested.emit(options)

	var chosen_tenant: TenantInstance = await _tenant_choice_submitted

	return chosen_tenant


func submit_tenant_choice(tenant_instance: TenantInstance) -> void:
	if not _pending_tenant_options.has(tenant_instance):
		push_warning(
			"ActionContext: Ignored a tenant choice that was not offered."
		)
		return

	_pending_tenant_options.clear()
	_tenant_choice_submitted.emit(tenant_instance)


func choose_cell(
	valid_positions: Array[Vector2i],
	prompt: String
) -> Vector2i:
	_pending_valid_positions = valid_positions.duplicate()
	cell_choice_requested.emit(valid_positions, prompt)

	var chosen_position: Vector2i = await _cell_choice_submitted

	return chosen_position


func submit_cell_choice(grid_position: Vector2i) -> void:
	if not _pending_valid_positions.has(grid_position):
		push_warning(
			"ActionContext: Ignored a cell choice that was not offered: %s."
			% grid_position
		)
		return

	_pending_valid_positions.clear()
	_cell_choice_submitted.emit(grid_position)


func get_occupied_positions() -> Array[Vector2i]:
	return building_state.get_occupied_positions()


func remove_tenant(grid_position: Vector2i) -> bool:
	# A removed tenant goes to the tenant discard pile until the round ends.
	var removed_tenant: TenantInstance = building_state.remove_tenant(
		grid_position
	)

	if removed_tenant == null:
		return false

	tenant_bag.discard(removed_tenant)
	events.append(
		GameEvent.new(GameEvent.Trigger.REMOVAL, removed_tenant, grid_position)
	)

	return true


func swap_tenants(first_position: Vector2i, second_position: Vector2i) -> bool:
	if not building_state.swap_tenants(first_position, second_position):
		return false

	# One event per tenant that moved, each at its new cell.
	events.append(GameEvent.new(
		GameEvent.Trigger.SWAP,
		building_state.get_tenant_at(first_position),
		first_position
	))
	events.append(GameEvent.new(
		GameEvent.Trigger.SWAP,
		building_state.get_tenant_at(second_position),
		second_position
	))

	return true


func get_transform_options(
	current_resource: TenantResource
) -> Array[TenantResource]:
	# The different tenant types the player owns (not the current one).
	var options: Array[TenantResource] = []

	for roster_tenant: TenantInstance in tenant_bag.roster:
		var roster_resource: TenantResource = roster_tenant.base_resource

		if roster_resource != current_resource and not options.has(roster_resource):
			options.append(roster_resource)

	return options


func transform_tenant(
	grid_position: Vector2i,
	new_tenant_resource: TenantResource
) -> bool:
	if not building_state.transform_tenant(grid_position, new_tenant_resource):
		return false

	events.append(GameEvent.new(
		GameEvent.Trigger.TRANSFORMATION,
		building_state.get_tenant_at(grid_position),
		grid_position
	))

	return true


func send_tenant_back_to_bag(grid_position: Vector2i) -> bool:
	# Like remove_tenant(), but the tenant goes back into the bag so it can
	# be drawn again this round.
	var removed_tenant: TenantInstance = building_state.remove_tenant(
		grid_position
	)

	if removed_tenant == null:
		return false

	tenant_bag.return_to_bag(removed_tenant)
	events.append(
		GameEvent.new(GameEvent.Trigger.REMOVAL, removed_tenant, grid_position)
	)

	return true


func move_tenant(from_position: Vector2i, to_position: Vector2i) -> bool:
	# Moving is not one of the trigger events, so it records nothing.
	return building_state.move_tenant(from_position, to_position)
