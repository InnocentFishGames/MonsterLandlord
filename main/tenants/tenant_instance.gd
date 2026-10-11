class_name TenantInstance
extends RefCounted


var tenant_resource: TenantResource


func _init(new_tenant_resource: TenantResource) -> void:
	if new_tenant_resource == null:
		push_error(
			"TenantInstance: Cannot create tenant because TenantResource is null."
		)
		return

	tenant_resource = new_tenant_resource
