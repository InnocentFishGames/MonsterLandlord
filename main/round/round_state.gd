class_name RoundState
extends RefCounted


# Announces the new number of plays left, so the interface can update.
signal plays_changed(plays_remaining: int)
# Announces that the round is over. Game decides what happens next.
signal round_ended()


var plays_remaining: int = 0
var is_active: bool = false


func start_round(play_count: int) -> bool:
	if play_count <= 0:
		push_error("RoundState: A round needs at least one action play.")
		return false

	plays_remaining = play_count
	is_active = true
	plays_changed.emit(plays_remaining)

	return true


func can_afford_play(play_cost: int) -> bool:
	return is_active and plays_remaining >= play_cost


func spend_plays(play_cost: int) -> bool:
	# Not having enough plays is normal gameplay, so reject quietly.
	if not can_afford_play(play_cost):
		return false

	plays_remaining -= play_cost
	plays_changed.emit(plays_remaining)

	return true


func add_plays(extra_plays: int) -> void:
	# Only for effects that explicitly say they grant plays. Drawing cards
	# never calls this.
	if extra_plays <= 0:
		push_warning("RoundState: add_plays() needs a positive amount.")
		return

	plays_remaining += extra_plays
	plays_changed.emit(plays_remaining)


func end_round() -> void:
	# Safe to call twice: only the first call announces the end.
	if not is_active:
		return

	is_active = false
	round_ended.emit()
