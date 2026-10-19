class_name HUD
extends CanvasLayer


signal next_month_requested()
signal restart_requested()
# Temporary test hook until room rewards or purchases exist.
signal place_room_requested()
# Skips the current draft round without picking a tenant.
signal skip_draft_requested()
# Ends drafting early and goes straight to rent collection.
signal collect_rent_requested()


@export var rent_display: RentDisplay
@export var next_month_button: Button
@export var restart_button: Button
@export var place_room_button: Button
@export var skip_draft_button: Button
@export var collect_rent_button: Button


func initialize() -> bool:
	if rent_display == null:
		push_error(
			"HUD: RentDisplay has not been assigned."
		)
		return false

	if next_month_button == null:
		push_error(
			"HUD: Next Month Button has not been assigned."
		)
		return false

	if restart_button == null:
		push_error(
			"HUD: Restart Button has not been assigned."
		)
		return false

	if place_room_button == null:
		push_error(
			"HUD: Place Room Button has not been assigned."
		)
		return false

	if skip_draft_button == null:
		push_error(
			"HUD: Skip Draft Button has not been assigned."
		)
		return false

	if collect_rent_button == null:
		push_error(
			"HUD: Collect Rent Button has not been assigned."
		)
		return false

	if not rent_display.initialize():
		return false

	next_month_button.pressed.connect(
		_on_next_month_button_pressed
	)

	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	skip_draft_button.pressed.connect(
		_on_skip_draft_button_pressed
	)

	collect_rent_button.pressed.connect(
		_on_collect_rent_button_pressed
	)

	place_room_button.pressed.connect(
		_on_place_room_button_pressed
	)

	# Month results start hidden. Place Room stays visible during play.
	next_month_button.hide()
	restart_button.hide()

	return true


func set_next_month_available(available: bool) -> void:
	next_month_button.visible = available


func set_restart_available(available: bool) -> void:
	restart_button.visible = available


func set_draft_controls_available(available: bool) -> void:
	# The skip and collect buttons only make sense while drafting.
	skip_draft_button.visible = available
	collect_rent_button.visible = available


func set_place_room_available(available: bool) -> void:
	place_room_button.visible = available


func _on_next_month_button_pressed() -> void:
	next_month_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_place_room_button_pressed() -> void:
	place_room_requested.emit()


func _on_skip_draft_button_pressed() -> void:
	skip_draft_requested.emit()


func _on_collect_rent_button_pressed() -> void:
	collect_rent_requested.emit()
