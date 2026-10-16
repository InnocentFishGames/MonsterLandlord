class_name TenantResource
extends Resource


enum Rarity {
	COMMON,
	UNCOMMON,
	RARE
}

enum TenantType {
	HUMAN,
	VAMPIRE,
	WEREWOLF
}


@export var tenant_name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var tenant_type: TenantType = TenantType.HUMAN
@export var base_rent: int = 10
@export var is_permanent: bool = false
@export var rent_effects: Array[RentEffect] = []


func validate() -> bool:
	# An empty effects array is valid; an empty entry is not.
	for index: int in range(rent_effects.size()):
		if rent_effects[index] == null:
			push_error(
				"TenantResource '%s': Rent effect slot %d is empty."
				% [tenant_name, index]
			)
			return false

	return true
