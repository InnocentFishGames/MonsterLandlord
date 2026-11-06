class_name TenantBag
extends RefCounted


# The player's tenant roster for the whole run, plus where each tenant is
# during the current round.
#
# Every tenant is in exactly one place:
#   - the bag (can still be drawn),
#   - the discard pile (cannot be drawn again this round),
#   - the building (BuildingState owns that, not this class), or
#   - in the player's hands for a moment, between draw_random() and the
#     placement or discard that follows it.
#
# `roster` is the source of truth for "which tenants does the player own".
# At the end of a round, return_all_to_bag() puts every roster tenant back.

var roster: Array[TenantInstance] = []
var bag: Array[TenantInstance] = []
var discard_pile: Array[TenantInstance] = []


func setup(starting_tenants: Array[TenantResource]) -> bool:
	# Validate external data entering the bag.
	if starting_tenants.is_empty():
		push_error(
			"TenantBag: Starting tenants is empty. Assign TenantResources to the starting roster."
		)
		return false

	var new_roster: Array[TenantInstance] = []

	for tenant_resource: TenantResource in starting_tenants:
		if tenant_resource == null:
			push_error(
				"TenantBag: Starting tenants contains an empty slot."
			)
			return false

		if not tenant_resource.validate():
			return false

		new_roster.append(TenantInstance.new(tenant_resource))

	roster = new_roster
	return_all_to_bag()

	return true


func draw_random() -> TenantInstance:
	# Draws without replacement. An empty bag is normal gameplay, so this
	# returns null instead of reporting an error.
	if bag.is_empty():
		return null

	var random_index: int = randi_range(0, bag.size() - 1)
	var drawn_tenant: TenantInstance = bag[random_index]
	bag.remove_at(random_index)

	return drawn_tenant


func discard(tenant_instance: TenantInstance) -> void:
	# Used for unchosen draws and for tenants removed from the building.
	# They stay out of the bag until the round ends.
	if tenant_instance == null:
		push_error("TenantBag: Cannot discard a null TenantInstance.")
		return

	if not roster.has(tenant_instance):
		push_warning(
			"TenantBag: Discarded a tenant that is not part of the roster."
		)
		return

	discard_pile.append(tenant_instance)


func return_all_to_bag() -> void:
	# Round cleanup. Placed and discarded tenants all come back; nothing is
	# permanently lost. The caller is responsible for emptying the building.
	bag = roster.duplicate()
	discard_pile.clear()


func get_bag_size() -> int:
	return bag.size()


func get_discard_size() -> int:
	return discard_pile.size()
