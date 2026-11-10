@abstract
class_name PersistentBonus
extends Resource


# A bonus the player owns for the rest of the run (bought in the shop).
# Not tied to a tenant. Defined in the Inspector and read-only during play.
# In a chain, tenants answer an event first, then the bonuses in the order
# the player bought them.

@export var bonus_name: String = ""
@export_multiline var description: String = ""
# What event wakes this bonus up.
@export var trigger: GameEvent.Trigger = GameEvent.Trigger.ROUND_END
# What the shop charges, in shop money.
@export var shop_price: int = 6


@abstract func execute(context: AbilityContext) -> void
