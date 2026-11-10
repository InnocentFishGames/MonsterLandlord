class_name TenantChoiceUI
extends CanvasLayer


# The player picked one of the offered tenants. Game passes it on.
signal tenant_chosen(tenant_instance: TenantInstance)


@export var choices_panel: Control
# Holds one button per offered tenant. Rebuilt every time choices are shown.
@export var cards_container: HBoxContainer


func initialize() -> bool:
	if choices_panel == null:
		push_error("TenantChoiceUI: Choices Panel has not been assigned.")
		return false

	if cards_container == null:
		push_error("TenantChoiceUI: Cards Container has not been assigned.")
		return false

	choices_panel.hide()

	return true


func show_choices(options: Array[TenantInstance]) -> void:
	_clear_cards()

	for tenant_instance: TenantInstance in options:
		var tenant_resource: TenantResource = tenant_instance.tenant_resource

		# Placeholder card: a plain button until the final art exists.
		var card_button: Button = Button.new()
		card_button.custom_minimum_size = Vector2(210, 240)
		card_button.text = "%s\n%s" % [
			tenant_resource.tenant_name,
			tenant_resource.get_summary()
		]
		card_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_button.pressed.connect(
			_on_card_button_pressed.bind(tenant_instance)
		)

		cards_container.add_child(card_button)

	choices_panel.show()


func hide_choices() -> void:
	_clear_cards()
	choices_panel.hide()


func _clear_cards() -> void:
	for child: Node in cards_container.get_children():
		cards_container.remove_child(child)
		child.queue_free()


func _on_card_button_pressed(tenant_instance: TenantInstance) -> void:
	# Close first so the choice cannot be answered twice.
	hide_choices()
	tenant_chosen.emit(tenant_instance)
