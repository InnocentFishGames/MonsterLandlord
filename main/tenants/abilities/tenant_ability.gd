@abstract
class_name TenantAbility
extends Resource


# One thing a tenant does when something happens. Defined in the Inspector
# and read-only during play. Each tenant lists its abilities in
# TenantResource.abilities; they run in that order.

# What event wakes this ability up. All current abilities pay rent at round end.
@export var trigger: GameEvent.Trigger = GameEvent.Trigger.ROUND_END
# Off: only events about the ability's own tenant count.
# On: events about any tenant count (for "when another tenant arrives").
@export var reacts_to_other_tenants: bool = false


# Does this ability want to run for this event?
func reacts_to(game_event: GameEvent, source_tenant: TenantInstance) -> bool:
	if game_event.trigger != trigger:
		return false

	# Round end and similar events are not about one tenant: everyone hears them.
	if game_event.tenant == null:
		return true

	return reacts_to_other_tenants or game_event.tenant == source_tenant


@abstract func execute(
	context: AbilityContext,
	source_tenant: TenantInstance,
	source_position: Vector2i
) -> void
