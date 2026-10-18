# Monster Landlord V2 (Godot 4.7, GDScript)

Rules for all code in this project. The user handles git and version control; do not commit.

## Approach
- The current project is the source of truth. Don't assume systems that haven't been provided.
- Use the simplest suitable solution. Add complexity only for a current problem or an explicitly agreed feature. No speculative architecture.
- Keep components focused on one responsibility. Prefer composition over deep custom inheritance.
- Make focused changes. Improve existing systems as needed; avoid unrelated rewrites.
- Distinguish code inspection from actual Godot testing when reporting results.

## Architecture
- `Game` initializes systems, connects events, and coordinates gameplay. Shared ancestors arrange communication.
- "Signal up, call down" is a guideline. Methods perform operations or return queries; signals announce events. Calls are not limited to direct children. No signal relays unless they aggregate dynamic children, add context, or protect a real boundary.
- Explicit dependencies: Inspector `@export` references or `setup()` / `initialize()` injection. No `get_parent()` for dependency discovery. No absolute or hardcoded NodePaths. Cached lookups inside one scene are fine.
- Protect meaningful scene boundaries with methods; add forwarding methods only when they protect that boundary.
- Scene hierarchy reflects lifetime: a node is a child when freeing its parent should free it.
- Node = scene-tree behavior. Resource = Inspector-editable or saved definitions. RefCounted = runtime objects without the scene tree.
- Resources define content; systems run gameplay; instances hold individual state. Gameplay logic must not depend on visuals.
- Shared definitions (RoomResource, TenantResource, effects) are read-only during play.
- One source of truth per state. Use methods like `add_room()` / `assign_tenant()`; never modify another system's collections directly.
- Initialization order: configure dependencies, connect signals, then start gameplay. Children run `_ready()` before parents. If `initialize()` / `setup()` fails, stop dependent work.
- No Autoloads or global event bus for local gameplay.

## Code style
- Static typing everywhere practical (variables, parameters, returns, signals, arrays, dictionaries). Descriptive names.
- Never use `assert()`. Validate Inspector dependencies in `_ready()` / `setup()`, external arguments when invalid values are realistic, and resources/instances where ownership is accepted. Don't re-check state already guaranteed.
- `push_error()` for broken requirements, `push_warning()` for recoverable or suspicious states. Expected rejections (e.g. occupied room) are normal gameplay, not errors. Error messages say what is missing and how to assign it.
- Update mechanism: input callbacks for input, signals for state changes, `_process()` only while needed, `_physics_process()` for physics, timers for periodic work.
- Simple typed data structures; add caches only for a demonstrated need.
- Files organized by feature. snake_case files and folders, PascalCase classes and nodes.

## Explaining code
The user is a beginner. Comment the purpose and reasoning, state any editor setup steps, and say clearly what changes and where. Give complete replacement functions when asked.
