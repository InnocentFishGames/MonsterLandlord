class_name HUD
extends CanvasLayer


signal next_month_requested()
signal restart_requested()


@export var rent_display: RentDisplay
@export var next_month_button: Button
@export var restart_button: Button


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

	if not rent_display.initialize():
		return false

	next_month_button.pressed.connect(
		_on_next_month_button_pressed
	)

	restart_button.pressed.connect(
		_on_restart_button_pressed
	)

	# Neither action is available before the first result.
	next_month_button.hide()
	restart_button.hide()

	return true


func set_next_month_available(available: bool) -> void:
	next_month_button.visible = available


func set_restart_available(available: bool) -> void:
	restart_button.visible = available


func _on_next_month_button_pressed() -> void:
	next_month_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()
