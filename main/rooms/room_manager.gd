class_name RoomManager
extends Node2D


signal tenant_assigned(
	tenant_instance: TenantInstance
)


# Announces a room after it has been added successfully.
# Game can connect to that room's interaction signals.
signal room_added(room: Room)


@export var grid_component: GridComponent
@export var room_scene: PackedScene


var rooms: Array[RoomInstance] = []


func initialize() -> bool:
	# Validate the Inspector dependencies owned by RoomManager.
	if grid_component == null:
		push_error(
			"RoomManager: GridComponent has not been assigned."
		)
		return false

	if room_scene == null:
		push_error(
			"RoomManager: RoomScene has not been assigned."
		)
		return false

	return true

func add_room(room_instance: RoomInstance) -> bool:
	# RoomInstance enters RoomManager here, so validate it.
	if room_instance == null:
		push_error(
			"RoomManager: Cannot add a null RoomInstance."
		)
		return false

	# Check whether the room can be placed at this position.
	if not can_place_room(
		room_instance.room_resource,
		room_instance.grid_position
	):
		return false
		
	# can_place_room() already checked that the resource exists.
	# Validate its effects before registering the room.
	if not room_instance.room_resource.validate():
		return false
		
	# PackedScene only guarantees that instantiate() returns a Node,
	# so verify that the configured scene is actually a Room.
	var room_node: Node = room_scene.instantiate()

	if not room_node is Room:
		push_error(
			"RoomManager: Room scene root must be a Room."
		)
		room_node.queue_free()
		return false

	var room: Room = room_node as Room

	var world_position: Vector2 = (
		grid_component.grid_to_world_position(
			room_instance.grid_position
		)
	)

	room.position = world_position

	# Convert the room's cell footprint into full pixel dimensions.
	var room_pixel_size: Vector2 = (
		Vector2(room_instance.room_resource.size)
		* grid_component.grid_size
	)

	if not room.setup(room_instance, room_pixel_size):
		room.queue_free()
		return false
			
	room.tenant_assigned.connect(
		_on_room_tenant_assigned
	)
	rooms.append(room_instance)

	add_child(room)
	# The room has been configured and added before other systems
	# receive it. Emit only when room creation succeeds.
	room_added.emit(room)
	
	return true


func can_place_room(
	room_resource: RoomResource,
	grid_position: Vector2i
) -> bool:
	# RoomResource can enter this public operation from outside
	# RoomManager, so keep this boundary validation.
	if room_resource == null:
		push_error(
			"RoomManager: Cannot check placement with a null RoomResource."
		)
		return false

	# First make sure the entire room fits inside the grid.
	if not grid_component.can_fit_room(
		grid_position,
		room_resource.size
	):
		return false

	# Then check every cell for another room.
	for x: int in range(room_resource.size.x):
		for y: int in range(room_resource.size.y):
			var cell_position: Vector2i = (
				grid_position + Vector2i(x, y)
			)

			if is_grid_position_occupied(cell_position):
				return false

	return true


func is_grid_position_occupied(
	grid_position: Vector2i
) -> bool:
	for room_instance: RoomInstance in rooms:
		var room_start: Vector2i = (
			room_instance.grid_position
		)

		var room_end: Vector2i = (
			room_start + room_instance.room_resource.size
		)

		if (
			grid_position.x >= room_start.x
			and grid_position.x < room_end.x
			and grid_position.y >= room_start.y
			and grid_position.y < room_end.y
		):
			return true

	return false


func is_full() -> bool:
	if rooms.is_empty():
		return false

	for room_instance: RoomInstance in rooms:
		if not room_instance.is_occupied():
			return false

	return true


func _on_room_tenant_assigned(
	tenant_instance: TenantInstance
) -> void:
	tenant_assigned.emit(tenant_instance)


func get_room_at_grid_position(
	grid_position: Vector2i
) -> RoomInstance:
	# Finds the room occupying a specific grid cell.
	#
	# This is useful for gameplay systems that need to inspect nearby
	# rooms without knowing how RoomManager stores its room collection.

	for room_instance: RoomInstance in rooms:
		var room_start: Vector2i = room_instance.grid_position
		var room_end: Vector2i = (
			room_start + room_instance.room_resource.size
		)

		if (
			grid_position.x >= room_start.x
			and grid_position.x < room_end.x
			and grid_position.y >= room_start.y
			and grid_position.y < room_end.y
		):
			return room_instance

	return null


func get_neighbor_rooms(
	room_instance: RoomInstance
) -> Array[RoomInstance]:
	# Collect cells immediately outside the room's four edges.
	# Corner cells are excluded because diagonal rooms aren't neighbors.
	var start: Vector2i = room_instance.grid_position
	var size: Vector2i = room_instance.room_resource.size

	var edge_cells: Array[Vector2i] = []

	# Cells above and below the room.
	for x: int in range(size.x):
		edge_cells.append(start + Vector2i(x, -1))
		edge_cells.append(start + Vector2i(x, size.y))

	# Cells to the left and right of the room.
	for y: int in range(size.y):
		edge_cells.append(start + Vector2i(-1, y))
		edge_cells.append(start + Vector2i(size.x, y))

	var neighbors: Array[RoomInstance] = []

	for cell: Vector2i in edge_cells:
		var neighbor: RoomInstance = get_room_at_grid_position(cell)

		# An empty cell or a cell outside the building has no room.
		if neighbor == null:
			continue

		# A large neighbor may touch several edge cells.
		# Count that room once, regardless of the shared edge length.
		if neighbors.has(neighbor):
			continue

		neighbors.append(neighbor)

	return neighbors

func remove_temporary_tenants() -> void:
	# RoomManager creates Room nodes as its direct children.
	# Ignore any other child nodes, such as future helper components.
	for child: Node in get_children():
		if child is not Room:
			continue

		var room: Room = child as Room

		# An empty room has no tenant to remove.
		if not room.room_instance.is_occupied():
			continue

		var tenant: TenantInstance = (
			room.room_instance.tenant_instance
		)

		# Permanent tenants remain between months.
		if tenant.tenant_resource.is_permanent:
			continue

		# Let Room perform the removal so its label, visual,
		# and drop availability update alongside its stored data.
		room.remove_tenant()
