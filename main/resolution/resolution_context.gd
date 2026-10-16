class_name ResolutionContext
extends RefCounted


var room_manager: RoomManager

var override_room: RoomInstance = null
var override_tenant: TenantInstance = null


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
