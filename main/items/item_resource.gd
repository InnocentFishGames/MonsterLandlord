class_name ItemResource
extends Resource


# A one-time-use item. The player holds up to RunState.ITEM_SLOT_COUNT of them
# and can use one at any time between action cards. Using it runs its effects
# (the same ActionEffects that cards use) and then it is gone.
# Read-only during play.

@export var item_name: String = ""
@export_multiline var description: String = ""
# What the shop charges, in shop money.
@export var shop_price: int = 5
# What the item does. The effects run in this order.
@export var effects: Array[ActionEffect] = []


func validate() -> bool:
	if effects.is_empty():
		push_error(
			"ItemResource '%s': An item needs at least one effect." % item_name
		)
		return false

	for index: int in range(effects.size()):
		if effects[index] == null:
			push_error(
				"ItemResource '%s': Effect slot %d is empty."
				% [item_name, index]
			)
			return false

	return true


func can_use(context: ActionContext) -> bool:
	# At least one effect must have something to do, so an item is never
	# wasted on nothing.
	for action_effect: ActionEffect in effects:
		if action_effect.can_resolve(context):
			return true

	return false
