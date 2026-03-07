# Copilot instructions for this Godot 4.6 project

Purpose: help AI coding agents become productive quickly by documenting project structure, patterns, and concrete examples.

- **Big picture**: This is a Godot 4.x game (project.godot shows `config/features` containing "4.6"). Scenes live in `Scenes/`, reusable code lives in top-level `.gd` scripts and `Scripts/` (when present), and assets are under `Assets/` and several asset-pack folders. Core gameplay nodes are composed as small scenes (e.g. enemies in `enemies/`, pickups in `Scenes/pick_up_item.tscn`). See [project.godot](project.godot) to verify autoloads and main scene.

- **Autoloads / singletons**: Check `[autoload]` in `project.godot` — this project uses `Global` and `TransitionChangeManager` as singletons. Do not replace their APIs; integrate with them when coordinating global state or scene transitions.

- **Run / debug**: Use Godot 4.6 editor or CLI. From the repo root the common commands are:

  - Open editor: `godot --path .` (or `godot4 --path .` depending on your installation).
  - Run headless or export tasks require Godot export templates; open the project in the editor when unsure.

- **Key patterns & examples**:
  - Health & signals: `Scenes/health_system.gd` implements `signal died` and `signal damage_taken`. Components call `health_system.init(health)`, call `apply_damage(...)`, and connect to `died`. Prefer reusing this pattern for new enemies.
  - Enemy template: `spider.gd` (in repo root) shows typical structure: exported variables for tuning (`@export var speed`), `@onready` typed node refs, `preload("res://Scenes/pick_up_item.tscn")`, and usage of `move_and_slide()`/`CharacterBody2D` physics. Mirror its signal handling and deferred collision disabling on death.
  - Scene switching: `get_tree().change_scene_to_file("res://Scenes/world.tscn")` is used (see `main_menu.gd`). Use `change_scene_to_file` rather than manipulating tree root in most cases.
  - Animation conventions: AnimatedSprite2D child nodes tend to provide `play_movement_animation(direction)` and `play_idle_animation()`; keep these method names when adding compatible animated sprites.

- **Coding conventions discovered**:
  - GDScript is typed (e.g., `func _physics_process(delta: float) -> void:`). Use typed signatures where possible.
  - Exported tuning variables use `@export` for editor exposure.
  - Use `@onready` to capture child nodes and type them (e.g., `@onready var health_system: HealthSystem = $HealthSystem`).
  - Prefer `preload("res://...")` for scene references and `instantiate()` when spawning.

- **When changing or adding files**:
  - If you add new autoload behavior, update `project.godot`'s `[autoload]` section and follow existing singleton patterns.
  - When adding enemies, follow `spider.gd` pattern: exported tuning parameters, a `HealthSystem` child, signals connection to `died`, and safe collision disabling via `set_deferred("disabled", true)`.

- **Assets & imports**: Many imported images and asset-pack folders include `.import` files. Do not edit .import files directly; edit original resources under `Assets/` or the pack folders and re-import in Godot.

- **Files to inspect first** (examples):
  - [project.godot](project.godot) — engine version, autoloads, main scene
  - [main_menu.gd](main_menu.gd) — scene-switching and UI patterns
  - [spider.gd](spider.gd) — enemy pattern and animation integration
  - [Scenes/health_system.gd](Scenes/health_system.gd) — health + signals
  - [Scenes/pick_up_item.tscn](Scenes/pick_up_item.tscn) and [Scenes/player.tscn](Scenes/player.tscn) — examples of instantiation/interaction

If any part of this guidance is unclear or you want more examples (e.g., an enemy scaffold or a quick test harness), tell me which area to expand and I will iterate.
