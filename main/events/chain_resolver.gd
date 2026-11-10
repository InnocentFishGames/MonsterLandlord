class_name ChainResolver
extends RefCounted


# Safety net against runaway chains. Loop prevention below normally stops a
# chain long before this; the limit protects against bugs.
const CHAIN_LIMIT: int = 200


# Runs one chain: the starting events, plus any events abilities raise on the
# way. Returns how many abilities ran.
#
# Rules:
# - Events are handled in the order they were raised (first in, first out).
# - For one event, tenants answer from top-left to bottom-right, and each
#   tenant's abilities run in the order listed on the tenant.
# - The same ability on the same tenant runs at most once per chain, so
#   two tenants that keep triggering each other cannot loop forever.
func resolve(
	starting_events: Array[GameEvent],
	context: AbilityContext
) -> int:
	var event_queue: Array[GameEvent] = starting_events.duplicate()
	var already_ran: Dictionary[String, bool] = {}
	var abilities_run: int = 0

	while not event_queue.is_empty():
		var current_event: GameEvent = event_queue.pop_front()

		# A snapshot of the cells: abilities may change the board mid-event.
		var positions: Array[Vector2i] = (
			context.building_state.get_positions_in_order()
		)

		for grid_position: Vector2i in positions:
			var tenant: TenantInstance = (
				context.building_state.get_tenant_at(grid_position)
			)

			if tenant == null:
				continue

			for ability: TenantAbility in tenant.tenant_resource.abilities:
				# Earlier abilities may have removed or replaced this tenant.
				if context.building_state.get_tenant_at(grid_position) != tenant:
					break

				if not ability.reacts_to(current_event, tenant):
					continue

				var key: String = "%d:%d" % [
					ability.get_instance_id(),
					tenant.get_instance_id()
				]

				if already_ran.has(key):
					continue

				if abilities_run >= CHAIN_LIMIT:
					push_warning(
						"ChainResolver: Chain stopped at the limit of %d abilities."
						% CHAIN_LIMIT
					)
					return abilities_run

				already_ran[key] = true
				abilities_run += 1
				ability.execute(context, tenant, grid_position)
				event_queue.append_array(context.take_raised_events())

		# Persistent bonuses answer after every tenant has answered.
		for bonus: PersistentBonus in context.persistent_bonuses:
			if bonus.trigger != current_event.trigger:
				continue

			var bonus_key: String = "bonus:%d" % bonus.get_instance_id()

			if already_ran.has(bonus_key):
				continue

			if abilities_run >= CHAIN_LIMIT:
				push_warning(
					"ChainResolver: Chain stopped at the limit of %d abilities."
					% CHAIN_LIMIT
				)
				return abilities_run

			already_ran[bonus_key] = true
			abilities_run += 1
			bonus.execute(context)
			event_queue.append_array(context.take_raised_events())

	return abilities_run
