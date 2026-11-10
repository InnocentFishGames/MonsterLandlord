class_name ShopUI
extends CanvasLayer


# The player clicked an offer. Game decides whether the purchase works.
signal offer_selected(offer: ShopOffer)
# The player picked one item from an opened pack.
signal pack_choice_selected(choice: ShopOffer)
# The player is done shopping and wants the next round.
signal continue_requested()


@export var shop_panel: Control
@export var title_label: Label
@export var money_label: Label
# One button per offer. Rebuilt whenever the shop changes.
@export var tenant_row: HBoxContainer
@export var action_row: HBoxContainer
# Bonuses and packs.
@export var extra_row: HBoxContainer
@export var continue_button: Button


func initialize() -> bool:
	if shop_panel == null:
		push_error("ShopUI: Shop Panel has not been assigned.")
		return false

	if title_label == null:
		push_error("ShopUI: Title Label has not been assigned.")
		return false

	if money_label == null:
		push_error("ShopUI: Money Label has not been assigned.")
		return false

	if tenant_row == null:
		push_error("ShopUI: Tenant Row has not been assigned.")
		return false

	if action_row == null:
		push_error("ShopUI: Action Row has not been assigned.")
		return false

	if extra_row == null:
		push_error("ShopUI: Extra Row has not been assigned.")
		return false

	if continue_button == null:
		push_error("ShopUI: Continue Button has not been assigned.")
		return false

	continue_button.pressed.connect(_on_continue_button_pressed)
	shop_panel.hide()

	return true


func show_shop(offers: Array[ShopOffer], shop_money: int) -> void:
	refresh(offers, shop_money)
	shop_panel.show()


func hide_shop() -> void:
	shop_panel.hide()


func refresh(offers: Array[ShopOffer], shop_money: int) -> void:
	title_label.text = "Shop"
	money_label.text = "Shop money: $%d" % shop_money
	continue_button.show()

	_clear_rows()

	for offer: ShopOffer in offers:
		var offer_button: Button = _make_card_button()

		if offer.is_sold:
			offer_button.text = "%s\nSold" % offer.get_title()
			offer_button.disabled = true
		else:
			offer_button.text = "%s  ($%d)\n%s" % [
				offer.get_title(), offer.price, offer.get_text()
			]
			offer_button.disabled = offer.price > shop_money
			offer_button.pressed.connect(
				_on_offer_button_pressed.bind(offer)
			)

		_row_for(offer).add_child(offer_button)


func show_pack_choices(choices: Array[ShopOffer]) -> void:
	# A pack is open: the player must pick one item before shopping on.
	title_label.text = "Choose one"
	continue_button.hide()

	_clear_rows()

	for choice: ShopOffer in choices:
		var choice_button: Button = _make_card_button()
		choice_button.text = "%s\n%s" % [choice.get_title(), choice.get_text()]
		choice_button.pressed.connect(
			_on_pack_choice_button_pressed.bind(choice)
		)

		_row_for(choice).add_child(choice_button)


func _make_card_button() -> Button:
	# Placeholder card: a plain button until the final art exists.
	var card_button: Button = Button.new()
	card_button.custom_minimum_size = Vector2(300, 240)
	card_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	return card_button


func _row_for(offer: ShopOffer) -> HBoxContainer:
	match offer.kind:
		ShopOffer.Kind.TENANT:
			return tenant_row
		ShopOffer.Kind.ACTION:
			return action_row
		_:
			return extra_row


func _clear_rows() -> void:
	for row: HBoxContainer in [tenant_row, action_row, extra_row]:
		for child: Node in row.get_children():
			row.remove_child(child)
			child.queue_free()


func _on_offer_button_pressed(offer: ShopOffer) -> void:
	offer_selected.emit(offer)


func _on_pack_choice_button_pressed(choice: ShopOffer) -> void:
	pack_choice_selected.emit(choice)


func _on_continue_button_pressed() -> void:
	continue_requested.emit()
