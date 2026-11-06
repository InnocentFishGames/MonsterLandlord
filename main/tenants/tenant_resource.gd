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
@export var base_rent: int = 10
@export var is_permanent: bool = false
@export var rent_effects: Array[RentEffect] = []


func has_tag(tag: Tag) -> bool:
	# Effects use this to ask "is this tenant a Human / Undead / ...?"
	return tags.has(tag)


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


func get_summary() -> String:
	# Player-facing text shared by the draft cards and the room tooltips.
	var tag_names: Array[String] = []

	for tag: Tag in tags:
		tag_names.append(Tag.keys()[tag].capitalize())

	var lines: Array[String] = []
	lines.append("Base rent: $%d" % base_rent)

	if not tag_names.is_empty():
		lines.append("Type: %s" % ", ".join(tag_names))

	if is_permanent:
		lines.append("Permanent: stays every month")

	if description != "":
		lines.append("")
		lines.append(description)

	return "\n".join(lines)
