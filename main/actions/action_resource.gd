class_name ActionResource
extends Resource


# An action card definition. Read-only during play: the deck moves
# references to these around, it never edits them.

@export var action_name: String = ""
@export_multiline var description: String = ""
# How many action plays this card costs. Almost every card costs 1.
@export var play_cost: int = 1
# What the shop charges, in shop money.
@export var shop_price: int = 4
# What the card does. The effects run in this order.
@export var effects: Array[ActionEffect] = []


func validate() -> bool:
	if play_cost < 0:
		push_error(
			"ActionResource '%s': Play cost cannot be negative."
			% action_name
		)
		return false

	for index: int in range(effects.size()):
		if effects[index] == null:
			push_error(
				"ActionResource '%s': Effect slot %d is empty."
				% [action_name, index]
			)
			return false

	return true


func can_play(context: ActionContext) -> bool:
	# A card with no effects at all is always playable. Otherwise at least
	# one effect must have something to do.
	if effects.is_empty():
		return true

	for action_effect: ActionEffect in effects:
		if action_effect.can_resolve(context):
			return true

	return false
