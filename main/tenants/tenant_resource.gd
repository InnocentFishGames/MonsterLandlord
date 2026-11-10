class_name TenantResource
extends Resource


enum Rarity {
	COMMON,
	UNCOMMON,
	RARE
}

# A tenant can have several tags, e.g. a Vampire is both VAMPIRE and UNDEAD.
# New tags go at the END so saved .tres files keep their numbers
# (HUMAN = 0, VAMPIRE = 1, WEREWOLF = 2, UNDEAD = 3, ZOMBIE = 4, WITCH = 5).
enum Tag {
	HUMAN,
	VAMPIRE,
	WEREWOLF,
	UNDEAD,
	ZOMBIE,
	WITCH
}


@export var tenant_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[Tag] = []
# What the shop charges, in shop money.
@export var shop_price: int = 4
# What this tenant does when events happen, in the order they run. Rent
# comes from abilities (for example FlatRentAbility), not from a base number.
@export var abilities: Array[TenantAbility] = []


func has_tag(tag: Tag) -> bool:
	return tags.has(tag)


func get_summary() -> String:
	# Player-facing text shared by the tenant cards and tooltips.
	var tag_names: Array[String] = []

	for tag: Tag in tags:
		tag_names.append(Tag.keys()[tag].capitalize())

	var lines: Array[String] = []

	if not tag_names.is_empty():
		lines.append("Type: %s" % ", ".join(tag_names))

	if description != "":
		lines.append("")
		lines.append(description)

	return "\n".join(lines)
