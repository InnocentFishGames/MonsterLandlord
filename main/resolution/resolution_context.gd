class_name ResolutionContext
extends RefCounted


var room_manager: RoomManager

var override_room: RoomInstance = null
var override_tenant: TenantInstance = null

# Occupied rooms in resolution order, set by ResolutionManager.
var resolution_order: Array[RoomInstance] = []

# Extra rent added to a room's tenant during this resolution.
var rent_bonuses: Dictionary[RoomInstance, int] = {}


func _init(new_room_manager: RoomManager) -> void:
	# Stores the real building state this resolution is based on.

	room_manager = new_room_manager


func set_tenant_override(
	room_instance: RoomInstance,
	tenant_instance: TenantInstance
) -> void:
	# Adds a hypothetical tenant to the resolution state without
	# changing the real RoomInstance.

	override_room = room_instance
	override_tenant = tenant_instance

func get_tenant(
	room_instance: RoomInstance
) -> TenantInstance:
	# Returns the hypothetical tenant when this is the overridden room.
	# Every other room uses its real tenant.

	if room_instance == override_room:
		return override_tenant

	return room_instance.tenant_instance


func is_room_occupied(
	room_instance: RoomInstance
) -> bool:
	# Occupancy must use the context rather than the real RoomInstance
	# because a previewed room may really be empty but hypothetically occupied.

	return get_tenant(room_instance) != null


func get_neighbor_rooms(
	room_instance: RoomInstance
) -> Array[RoomInstance]:
	# Hypothetical tenant placement changes occupancy, not room layout.
	# Use RoomManager for geometry while keeping effects dependent
	# on this context for their view of the building.
	return room_manager.get_neighbor_rooms(room_instance)


func set_resolution_order(
	new_resolution_order: Array[RoomInstance]
) -> void:
	# The occupied rooms in the order they resolve. ResolutionManager sets
	# this once per resolution so abilities can look at neighboring steps.
	resolution_order = new_resolution_order


func get_previous_room(
	room_instance: RoomInstance
) -> RoomInstance:
	# The occupied room that resolves just before this one, or null.
	var index: int = resolution_order.find(room_instance)

	if index <= 0:
		return null

	return resolution_order[index - 1]


func get_next_room(
	room_instance: RoomInstance
) -> RoomInstance:
	# The occupied room that resolves just after this one, or null.
	var index: int = resolution_order.find(room_instance)

	if index == -1 or index + 1 >= resolution_order.size():
		return null

	return resolution_order[index + 1]


func add_rent_bonus(
	room_instance: RoomInstance,
	amount: int
) -> void:
	# Extra rent for this room's tenant for the rest of this resolution
	# (that week). It lives here, not on the tenant, so previews never
	# change real tenants.
	rent_bonuses[room_instance] = get_rent_bonus(room_instance) + amount


func get_rent_bonus(room_instance: RoomInstance) -> int:
	if rent_bonuses.has(room_instance):
		return rent_bonuses[room_instance]

	return 0


func get_rooms_before(
	room_instance: RoomInstance
) -> Array[RoomInstance]:
	# Every occupied room that resolves earlier than this one.
	var rooms_before: Array[RoomInstance] = []

	for earlier_room: RoomInstance in resolution_order:
		if earlier_room == room_instance:
			break

		rooms_before.append(earlier_room)

	return rooms_before


func get_rooms_in_row(row: int) -> Array[RoomInstance]:
	# Hypothetical placement changes occupancy, not room layout,
	# so RoomManager answers this just like get_neighbor_rooms().
	return room_manager.get_rooms_in_row(row)
