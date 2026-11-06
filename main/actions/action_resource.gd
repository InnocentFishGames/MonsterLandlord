class_name ActionResource
extends Resource


# An action card definition. Read-only during play: the deck moves
# references to these around, it never edits them.
#
# What a card actually DOES (draw tenants, place, swap, ...) is added in a
# later step as an array of effect resources.

@export var action_name: String = ""
@export_multiline var description: String = ""
# How many action plays this card costs. Almost every card costs 1.
@export var play_cost: int = 1


func validate() -> bool:
	if play_cost < 0:
		push_error(
			"ActionResource '%s': Play cost cannot be negative."
			% action_name
		)
		return false

	return true
