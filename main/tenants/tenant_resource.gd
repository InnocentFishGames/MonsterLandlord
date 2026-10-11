class_name TenantResource
extends Resource


enum Rarity {
	COMMON,
	UNCOMMON,
	RARE
}


@export var tenant_name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var base_rent: int = 10
@export var is_permanent: bool = false
