@abstract
class_name ActionEffect
extends Resource


# One step of an action card. A card lists its effects in the Inspector and
# they run in that order. Effects are definitions and stay read-only:
# anything that changes goes through the ActionContext.
#
# execute() may use `await` (for example to wait for the player to choose).
# The caller always awaits it, so effects that finish at once are fine too.
#
# Partial resolution: do as much as possible, never undo, never refund.
@abstract
func execute(context: ActionContext) -> void


# Is there anything this effect could do right now? Cards where no effect
# can do anything are shown as unplayable and cannot be played, so the player
# never wastes a play. The default is "yes"; effects with targets override it.
# This only looks at the board and the bag. It never changes anything.
func can_resolve(_context: ActionContext) -> bool:
	return true
