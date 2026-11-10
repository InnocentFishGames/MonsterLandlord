class_name FlatRentBonus
extends PersistentBonus


# Used by: Landlord's Ledger (data/bonuses/ledger.tres).
@export var amount: int = 10


func execute(context: AbilityContext) -> void:
	context.add_bonus_rent(amount, self, "Flat bonus")
