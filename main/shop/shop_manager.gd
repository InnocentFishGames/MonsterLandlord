class_name ShopManager
extends Node


# The rooms the shop is allowed to offer. Assign RoomResources in the Inspector.
@export var available_rooms: Array[RoomResource] = []
# How many rooms each visit to the shop offers.
@export var offer_count: int = 3
# The first reroll in a shop visit costs the base price. Each reroll after
# that costs more. The price starts over on the next visit.
@export var reroll_base_price: int = 3
@export var reroll_price_increase: int = 2

# How many times the offers were rerolled during this shop visit.
var rerolls_used: int = 0


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

	if reroll_base_price < 0 or reroll_price_increase < 0:
		push_error(
			"ShopManager: Reroll prices cannot be negative."
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


func start_visit() -> void:
	# Each visit to the shop starts with the cheapest reroll again.
	rerolls_used = 0


func get_reroll_price() -> int:
	return reroll_base_price + rerolls_used * reroll_price_increase


func record_reroll() -> void:
	# Game calls this after the player has paid for a reroll.
	rerolls_used += 1
