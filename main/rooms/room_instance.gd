class_name RoomInstance
extends RefCounted


var room_resource: RoomResource
var grid_position: Vector2i

var tenant_instance: TenantInstance = null


func _init(
	new_room_resource: RoomResource,
	new_grid_position: Vector2i
) -> void:
	if new_room_resource == null:
		push_error(
			"RoomInstance: Cannot create room because RoomResource is null."
		)
		return

	room_resource = new_room_resource
	grid_position = new_grid_position

func assign_tenant(
	new_tenant_instance: TenantInstance
) -> bool:
	if new_tenant_instance == null:
		push_error(
			"RoomInstance: Cannot assign a null TenantInstance."
		)
		return false

	# Occupied rooms rejecting a new tenant is normal gameplay.
	if tenant_instance != null:
		return false

	tenant_instance = new_tenant_instance

	return true
	
func remove_tenant() -> TenantInstance:
	if tenant_instance == null:
		return null

	var removed_tenant: TenantInstance = tenant_instance
	tenant_instance = null
	return removed_tenant

func is_occupied() -> bool:
	return tenant_instance != null
