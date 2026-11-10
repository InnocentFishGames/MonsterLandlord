class_name ShopOffer
extends RefCounted


# One thing for sale (or, inside an opened pack, one thing to pick).
# Exactly one of the four resource fields is filled, matching `kind`.

enum Kind {
	TENANT,
	ACTION,
	BONUS,
	PACK
}

var kind: Kind
var tenant_resource: TenantResource = null
var action_resource: ActionResource = null
var bonus: PersistentBonus = null
var pack: PackResource = null
var price: int = 0
var is_sold: bool = false


static func for_tenant(new_tenant: TenantResource, new_price: int) -> ShopOffer:
	var offer: ShopOffer = ShopOffer.new(Kind.TENANT, new_price)
	offer.tenant_resource = new_tenant
	return offer


static func for_action(new_action: ActionResource, new_price: int) -> ShopOffer:
	var offer: ShopOffer = ShopOffer.new(Kind.ACTION, new_price)
	offer.action_resource = new_action
	return offer


static func for_bonus(new_bonus: PersistentBonus, new_price: int) -> ShopOffer:
	var offer: ShopOffer = ShopOffer.new(Kind.BONUS, new_price)
	offer.bonus = new_bonus
	return offer


static func for_pack(new_pack: PackResource, new_price: int) -> ShopOffer:
	var offer: ShopOffer = ShopOffer.new(Kind.PACK, new_price)
	offer.pack = new_pack
	return offer


func _init(new_kind: Kind, new_price: int) -> void:
	kind = new_kind
	price = new_price


func get_title() -> String:
	match kind:
		Kind.TENANT:
			return tenant_resource.tenant_name
		Kind.ACTION:
			return action_resource.action_name
		Kind.BONUS:
			return bonus.bonus_name
		_:
			return pack.pack_name


func get_text() -> String:
	match kind:
		Kind.TENANT:
			return tenant_resource.get_summary()
		Kind.ACTION:
			return action_resource.description
		Kind.BONUS:
			return bonus.description
		_:
			return pack.description
