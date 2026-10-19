class_name Wallet
extends RefCounted


# Emitted whenever the amount of cash changes, so the interface can update.
signal cash_changed(new_amount: int)


# The player's cash. Only add_cash() and try_spend() change it.
var cash: int = 0


func can_afford(price: int) -> bool:
	return cash >= price


func add_cash(amount: int) -> void:
	if amount < 0:
		push_warning(
			"Wallet: add_cash() received a negative amount. Use try_spend()."
		)
		return

	cash += amount
	cash_changed.emit(cash)


func try_spend(price: int) -> bool:
	# Not being able to afford something is normal gameplay, not an error.
	if price < 0 or not can_afford(price):
		return false

	cash -= price
	cash_changed.emit(cash)
	return true
