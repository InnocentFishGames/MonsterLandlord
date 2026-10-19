class_name ShopManager
extends Node


# The rooms the shop is allowed to offer. Assign RoomResources in the Inspector.
@export var available_rooms: Array[RoomResource] = []
# How many rooms each visit to the shop offers.
@export var offer_count: int = 3


func initialize() -> bool:
	if offer_count <= 0:
		push_error(
			"ShopManager: Offer Count must be greater than zero."
		)
		return false

	if available_rooms.size() < offer_count:
		push_error(
			"ShopManager: Available Rooms needs at least %d RoomResources."
			% offer_count
		)
		return false

	for room_resource: RoomResource in available_rooms:
		if room_resource == null:
			push_error(
				"ShopManager: Available Rooms contains an empty slot."
			)
			return false

		if not room_resource.validate():
			return false

	return true


func create_offers() -> Array[RoomResource]:
	# Picks distinct random rooms, so a room never appears twice in one visit.
	var room_pool: Array[RoomResource] = available_rooms.duplicate()
	room_pool.shuffle()

	var offers: Array[RoomResource] = []

	for index: int in range(offer_count):
		offers.append(room_pool[index])

	return offers
