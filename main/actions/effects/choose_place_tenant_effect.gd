class_name ChoosePlaceTenantEffect
extends ActionEffect


# Used by: Recruit (data/actions/recruit.tres).
# Draws tenants, the player keeps one and places it on any empty cell of
# their choice. The tenants not chosen go to the discard pile.

@export var draw_count: int = 3


func execute(context: ActionContext) -> void:
	var drawn_tenants: Array[TenantInstance] = context.draw_tenants(
		draw_count
	)

	# Empty bag: nothing to choose from, so this effect fizzles.
	if drawn_tenants.is_empty():
		return

	var empty_positions: Array[Vector2i] = context.get_empty_positions()

	# Full building: the drawn tenants have nowhere to go.
	if empty_positions.is_empty():
		context.discard_tenants(drawn_tenants)
		return

	var chosen_tenant: TenantInstance = await context.choose_tenant(
		drawn_tenants
	)

	# The unchosen tenants are discarded as soon as the choice is made.
	var unchosen_tenants: Array[TenantInstance] = drawn_tenants.duplicate()
	unchosen_tenants.erase(chosen_tenant)
	context.discard_tenants(unchosen_tenants)

	var chosen_position: Vector2i = await context.choose_cell(
		empty_positions,
		"Place %s: click a highlighted cell."
		% chosen_tenant.tenant_resource.tenant_name
	)

	if not context.place_tenant(
		chosen_position,
		chosen_tenant,
		GameEvent.Trigger.CHOSEN_PLACEMENT
	):
		# Should not happen, because the board cannot change during the
		# prompt. Discard rather than lose the tenant.
		context.discard_tenants([chosen_tenant])


func can_resolve(context: ActionContext) -> bool:
	# Needs a tenant in the bag and a free cell to put it in.
	return (
		context.tenant_bag.get_bag_size() > 0
		and not context.get_empty_positions().is_empty()
	)
