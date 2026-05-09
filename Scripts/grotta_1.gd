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
	if inside_scene:
		# Rimuove l'immagine della porta chiusa per mostrare la grotta sotto
		door_sprite.hide()
		# Attende un attimo per dare un effetto visivo di apertura
		await get_tree().create_timer(0.2).timeout
		
		# Salva la posizione e cambia scena
		Global.player_pos = $"../player".global_position if has_node("../player") else Vector2.ZERO
		get_tree().change_scene_to_packed(inside_scene)
