class_name RentResult
extends RefCounted


var total_rent: int = 0

# One entry per occupied room, in the order rooms were resolved.
var entries: Array[RentEntry] = []
