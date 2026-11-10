class_name ShopState
extends RefCounted


# What the shop can sell, and what it is offering right now. The pools are
# read-only definitions; each visit rolls a fresh set of offers.

var tenant_pool: Array[TenantResource] = []
var action_pool: Array[ActionResource] = []
var bonus_pool: Array[PersistentBonus] = []
var pack_pool: Array[PackResource] = []
var offers: Array[ShopOffer] = []


func setup(
	new_tenant_pool: Array[TenantResource],
	new_action_pool: Array[ActionResource],
	new_bonus_pool: Array[PersistentBonus] = [],
	new_pack_pool: Array[PackResource] = []
) -> bool:
	if (
		new_tenant_pool.is_empty() and new_action_pool.is_empty()
		and new_bonus_pool.is_empty() and new_pack_pool.is_empty()
	):
		push_error(
			"ShopState: All pools are empty. Assign tenants, actions, bonuses or packs the shop can sell."
		)
		return false

	for tenant_resource: TenantResource in new_tenant_pool:
		if tenant_resource == null:
			push_error("ShopState: The tenant pool contains an empty slot.")
			return false

	for action_resource: ActionResource in new_action_pool:
		if action_resource == null:
			push_error("ShopState: The action pool contains an empty slot.")
			return false

	for bonus: PersistentBonus in new_bonus_pool:
		if bonus == null:
			push_error("ShopState: The bonus pool contains an empty slot.")
			return false

	for pack: PackResource in new_pack_pool:
		if pack == null or not pack.validate():
			push_error("ShopState: The pack pool has an empty or invalid pack.")
			return false

	tenant_pool = new_tenant_pool.duplicate()
	action_pool = new_action_pool.duplicate()
	bonus_pool = new_bonus_pool.duplicate()
	pack_pool = new_pack_pool.duplicate()

	return true


func roll_offers(
	tenant_count: int,
	action_count: int,
	bonus_count: int,
	pack_count: int,
	owned_bonuses: Array[PersistentBonus]
) -> void:
	# Random picks without repeats within one visit. A small pool simply
	# gives fewer offers. Bonuses the player already owns are not offered.
	offers.clear()

	var shuffled_tenants: Array[TenantResource] = tenant_pool.duplicate()
	shuffled_tenants.shuffle()

	for index: int in range(mini(tenant_count, shuffled_tenants.size())):
		offers.append(ShopOffer.for_tenant(
			shuffled_tenants[index], shuffled_tenants[index].shop_price
		))

	var shuffled_actions: Array[ActionResource] = action_pool.duplicate()
	shuffled_actions.shuffle()

	for index: int in range(mini(action_count, shuffled_actions.size())):
		offers.append(ShopOffer.for_action(
			shuffled_actions[index], shuffled_actions[index].shop_price
		))

	var available_bonuses: Array[PersistentBonus] = []

	for bonus: PersistentBonus in bonus_pool:
		if not owned_bonuses.has(bonus):
			available_bonuses.append(bonus)

	available_bonuses.shuffle()

	for index: int in range(mini(bonus_count, available_bonuses.size())):
		offers.append(ShopOffer.for_bonus(
			available_bonuses[index], available_bonuses[index].shop_price
		))

	var shuffled_packs: Array[PackResource] = pack_pool.duplicate()
	shuffled_packs.shuffle()

	for index: int in range(mini(pack_count, shuffled_packs.size())):
		offers.append(ShopOffer.for_pack(
			shuffled_packs[index], shuffled_packs[index].shop_price
		))


func try_buy(
	offer: ShopOffer,
	run_state: RunState,
	tenant_bag: TenantBag,
	action_deck: ActionDeck
) -> bool:
	# Sold items and unaffordable items are normal rejections.
	if offer.is_sold or not offers.has(offer):
		return false

	if not run_state.try_spend_shop_money(offer.price):
		return false

	match offer.kind:
		ShopOffer.Kind.TENANT:
			tenant_bag.add_to_roster(offer.tenant_resource)
		ShopOffer.Kind.ACTION:
			action_deck.add_card(offer.action_resource)
		ShopOffer.Kind.BONUS:
			run_state.add_bonus(offer.bonus)
		ShopOffer.Kind.PACK:
			# Paying opens the pack; the player picks the item afterwards
			# (see roll_pack_choices and take_pack_choice).
			pass

	offer.is_sold = true

	return true


func roll_pack_choices(pack_offer: ShopOffer) -> Array[ShopOffer]:
	# The items shown when a pack is opened. They are free to pick (price 0).
	var choices: Array[ShopOffer] = []
	var pack: PackResource = pack_offer.pack

	if pack.is_tenant_pack():
		var shuffled_tenants: Array[TenantResource] = pack.tenants.duplicate()
		shuffled_tenants.shuffle()

		for index: int in range(mini(pack.choices_shown, shuffled_tenants.size())):
			choices.append(ShopOffer.for_tenant(shuffled_tenants[index], 0))
	else:
		var shuffled_actions: Array[ActionResource] = pack.actions.duplicate()
		shuffled_actions.shuffle()

		for index: int in range(mini(pack.choices_shown, shuffled_actions.size())):
			choices.append(ShopOffer.for_action(shuffled_actions[index], 0))

	return choices


func take_pack_choice(
	choice: ShopOffer,
	tenant_bag: TenantBag,
	action_deck: ActionDeck
) -> void:
	if choice.kind == ShopOffer.Kind.TENANT:
		tenant_bag.add_to_roster(choice.tenant_resource)
	elif choice.kind == ShopOffer.Kind.ACTION:
		action_deck.add_card(choice.action_resource)
	else:
		push_error("ShopState: A pack can only contain tenants or actions.")
