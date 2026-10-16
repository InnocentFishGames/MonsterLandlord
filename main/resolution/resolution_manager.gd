class_name ResolutionManager
extends Node


func resolve_building(
	room_manager: RoomManager
) -> RentResult:
	# Resolves the real building state using a normal resolution context.

	var result: RentResult = RentResult.new()

	if room_manager == null:
		push_error(
			"ResolutionManager: Cannot resolve a null RoomManager."
		)
		return result

	var context: ResolutionContext = ResolutionContext.new(
		room_manager
	)

	return _resolve_with_context(
		room_manager,
		context
	)

func _calculate_tenant_rent(
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int:
	# _resolve_with_context() only calls this for occupied rooms.
	# Read through the context so hypothetical tenants work in previews.
	var tenant_instance: TenantInstance = (
		context.get_tenant(room_instance)
	)

	var tenant_resource: TenantResource = (
		tenant_instance.tenant_resource
	)

	var rent: int = tenant_resource.base_rent

	# Apply tenant effects first.
	rent = _apply_rent_effects(
		rent,
		tenant_resource.rent_effects,
		room_instance,
		context
	)

	# Apply room effects afterward so rooms can amplify tenant rent.
	rent = _apply_rent_effects(
		rent,
		room_instance.room_resource.rent_effects,
		room_instance,
		context
	)

	return rent
	
func _get_rooms_in_resolution_order(
	rooms: Array[RoomInstance]
) -> Array[RoomInstance]:
	# Creates a copy so sorting does not modify RoomManager.rooms.
	#
	# Resolution starts at the top row and moves left to right:
	#
	# 1 → 2 → 3
	# 4 → 5 → 6
	# 7 → 8 → 9

	var ordered_rooms: Array[RoomInstance] = rooms.duplicate()

	ordered_rooms.sort_custom(
		func(
			room_a: RoomInstance,
			room_b: RoomInstance
		) -> bool:
			# Rooms on the same row are ordered from left to right.
			if (
				room_a.grid_position.y
				== room_b.grid_position.y
			):
				return (
					room_a.grid_position.x
					< room_b.grid_position.x
				)

			# Otherwise, rooms closer to the top resolve first.
			return (
				room_a.grid_position.y
				< room_b.grid_position.y
			)
	)

	return ordered_rooms


func _apply_rent_effects(
	current_rent: int,
	rent_effects: Array[RentEffect],
	room_instance: RoomInstance,
	context: ResolutionContext
) -> int:
	# Applies effects according to their declared stage so Inspector
	# array order cannot change additive-versus-multiplicative behavior.

	var rent: int = current_rent

	for stage: RentEffect.Stage in RentEffect.Stage.values():
		for rent_effect: RentEffect in rent_effects:
			if rent_effect.get_stage() != stage:
				continue

			rent = rent_effect.apply(
				rent,
				room_instance,
				context
			)

	return rent


func calculate_projected_rent(
	room_manager: RoomManager,
	target_room: RoomInstance,
	tenant_resource: TenantResource
) -> RentResult:
	# Calculates the building's rent as though the tenant were placed
	# in target_room without changing the real room occupancy.

	var projected_tenant: TenantInstance = TenantInstance.new(
		tenant_resource
	)

	var context: ResolutionContext = ResolutionContext.new(
		room_manager
	)

	context.set_tenant_override(
		target_room,
		projected_tenant
	)

	return _resolve_with_context(
		room_manager,
		context
	)


func _resolve_with_context(
	room_manager: RoomManager,
	context: ResolutionContext
) -> RentResult:
	# Runs the shared rent calculation using the supplied view of the
	# building state. Real resolution and previews both use this function.

	var result: RentResult = RentResult.new()

	var ordered_rooms: Array[RoomInstance] = (
		_get_rooms_in_resolution_order(
			room_manager.rooms
		)
	)

	for room_instance: RoomInstance in ordered_rooms:
		if not context.is_room_occupied(room_instance):
			continue

		var tenant_rent: int = _calculate_tenant_rent(
			room_instance,
			context
		)

		result.room_rent[room_instance] = tenant_rent
		result.total_rent += tenant_rent

	return result
