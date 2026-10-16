class_name TenantDropArea
extends Control


signal tenant_dropped(tenant_resource: TenantResource)
signal tenant_hovered(tenant_resource: TenantResource)


# Room updates this whenever its occupancy changes.
# Start disabled until Room supplies the initial state.
var accepts_tenant: bool = false


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	# Occupied rooms reject the drag without requesting a rent preview.
	if not accepts_tenant:
		return false

	# Drag data can come from other controls, so validate its type.
	if data is not TenantResource:
		return false

	var tenant_resource: TenantResource = data as TenantResource

	tenant_hovered.emit(tenant_resource)

	return true

func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:

	if not data is TenantResource:
		push_warning(
			"TenantDropArea: Received drag data that is not a TenantResource."
		)
		return

	var tenant_resource: TenantResource = data as TenantResource

	tenant_dropped.emit(tenant_resource)
