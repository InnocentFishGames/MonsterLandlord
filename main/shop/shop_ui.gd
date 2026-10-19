class_name ShopUI
extends CanvasLayer


# The player picked a room to buy. Game starts the placement.
signal offer_selected(room_resource: RoomResource)
# The player is done shopping.
signal continue_requested()
# The player backed out of placing a room and wants the shop again.
signal placement_back_requested()


# The shop screen: offers, cash, and the Continue button.
@export var shop_panel: Control
@export var offers_container: HBoxContainer
@export var cash_label: Label
@export var continue_button: Button
# Shown instead of the shop screen while a purchased room is being placed.
@export var placement_bar: Control
@export var placement_label: Label
@export var back_button: Button


func initialize() -> bool:
	if shop_panel == null:
		push_error("ShopUI: Shop Panel has not been assigned.")
		return false

	if offers_container == null:
		push_error("ShopUI: Offers Container has not been assigned.")
		return false

	if cash_label == null:
		push_error("ShopUI: Cash Label has not been assigned.")
		return false

	if continue_button == null:
		push_error("ShopUI: Continue Button has not been assigned.")
		return false

	if placement_bar == null:
		push_error("ShopUI: Placement Bar has not been assigned.")
		return false

	if placement_label == null:
		push_error("ShopUI: Placement Label has not been assigned.")
		return false

	if back_button == null:
		push_error("ShopUI: Back Button has not been assigned.")
		return false

	continue_button.pressed.connect(_on_continue_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	hide_shop()

	return true


func show_shop(
	offers: Array[RoomResource],
	cash: int
) -> void:
	# Rebuilds the cards each time, so a bought room simply disappears.
	_clear_offers()

	for room_resource: RoomResource in offers:
		# Placeholder card: a plain button until the final art exists.
		var offer_button: Button = Button.new()
		offer_button.custom_minimum_size = Vector2(220, 140)
		offer_button.text = (
			"%s\n$%d\n\n%s"
			% [
				room_resource.room_name,
				room_resource.price,
				room_resource.description
			]
		)
		offer_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Rooms the player cannot afford are visible but not selectable.
		offer_button.disabled = room_resource.price > cash
		offer_button.pressed.connect(
			_on_offer_button_pressed.bind(room_resource)
		)

		offers_container.add_child(offer_button)

	set_cash(cash)
	placement_bar.hide()
	shop_panel.show()


func hide_shop() -> void:
	_clear_offers()
	shop_panel.hide()
	placement_bar.hide()


func show_placement(room_resource: RoomResource) -> void:
	# Hides the shop so the whole building is visible for placing the room.
	shop_panel.hide()
	placement_label.text = (
		"Placing %s ($%d): %s"
		% [
			room_resource.room_name,
			room_resource.price,
			room_resource.description
		]
	)
	placement_bar.show()


func set_cash(cash: int) -> void:
	cash_label.text = "Cash: $%d" % cash


func _clear_offers() -> void:
	for child: Node in offers_container.get_children():
		offers_container.remove_child(child)
		child.queue_free()


func _on_offer_button_pressed(room_resource: RoomResource) -> void:
	offer_selected.emit(room_resource)


func _on_continue_button_pressed() -> void:
	continue_requested.emit()


func _on_back_button_pressed() -> void:
	placement_back_requested.emit()
