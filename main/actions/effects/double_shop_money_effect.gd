class_name DoubleShopMoneyEffect
extends ActionEffect


# Used by: Piggy Bank (data/items/piggy_bank.tres).
# Doubles the shop money the player holds right now.


func execute(context: ActionContext) -> void:
	context.run_state.add_shop_money(context.run_state.shop_money)


func can_resolve(context: ActionContext) -> bool:
	return context.run_state.shop_money > 0
