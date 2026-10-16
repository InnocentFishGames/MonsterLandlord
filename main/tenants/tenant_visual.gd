class_name TenantVisual
extends Node2D


var tenant_instance: TenantInstance = null


func setup(new_tenant_instance: TenantInstance) -> void:
	if new_tenant_instance == null:
		push_error(
			"TenantVisual: Cannot setup because TenantInstance is null."
		)
		return

	if new_tenant_instance.tenant_resource == null:
		push_error(
			"TenantVisual: Cannot setup because TenantResource is null."
		)
		return

	tenant_instance = new_tenant_instance

	queue_redraw()

func _draw() -> void:
	# Drawing may occur before a tenant has been supplied.
	if tenant_instance == null:
		return

	# Setup already validated the tenant's resource.
	# Room positions this node at the room's center.
	draw_circle(
		Vector2.ZERO,
		50.0,
		Color.WHITE
	)
