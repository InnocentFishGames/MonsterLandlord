class_name RoomResource
extends Resource


enum Rarity {
	COMMON,
	UNCOMMON,
	RARE
}


@export var name: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var size: Vector2i = Vector2i(1, 1)
