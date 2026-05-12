extends Node2D

@export var inside_scene: PackedScene
@onready var door_sprite = $DoorWay/Sprite2D

func _ready() -> void:
	pass

func _on_door_way_body_entered(body: Node2D) -> void:
	if body.name == "player":
		body.house = self

func _on_door_way_body_exited(body: Node2D) -> void:
	if body.name == "player":
		if body.house == self:
			body.house = null

func enter():
	var target = inside_scene
	if not target:
		target = load("res://Scenes/dungeon_2.tscn")
		
	if target:
		# Rimuove l'immagine della porta chiusa per mostrare la grotta sotto
		door_sprite.hide()
		# Attende un attimo per dare un effetto visivo di apertura
		await get_tree().create_timer(0.2).timeout
		
		# Salva la posizione e cambia scena
		Global.from_grotta2_to_dungeon2 = true
		
		Global.player_pos = $"../player".global_position if has_node("../player") else Vector2.ZERO
		if TransitionChangeManager:
			TransitionChangeManager.change_scene(target)
		else:
			get_tree().change_scene_to_packed(target)
