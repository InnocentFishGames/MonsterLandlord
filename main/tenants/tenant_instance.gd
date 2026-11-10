class_name TenantInstance
extends RefCounted


# What this tenant is right now. Transformations change it for the rest of
# the round only; reset_transformation() brings back the original.
var tenant_resource: TenantResource
# What this tenant really is. Never changes.
var base_resource: TenantResource


func _init(new_tenant_resource: TenantResource) -> void:
	if new_tenant_resource == null:
		push_error(
			"TenantInstance: Cannot create tenant because TenantResource is null."
		)
		return

	tenant_resource = new_tenant_resource
	base_resource = new_tenant_resource


func transform_to(new_tenant_resource: TenantResource) -> void:
	tenant_resource = new_tenant_resource


func reset_transformation() -> void:
	tenant_resource = base_resource
