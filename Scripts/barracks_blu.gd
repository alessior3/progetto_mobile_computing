extends Node2D

@onready var player = $"../player"

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_door_way_body_entered(body: Node2D) -> void:
	body.house = self

func _on_door_way_body_exited(body: Node2D) -> void:
	if body.house == self:
		body.house = null

func enter():
	var p = get_tree().get_first_node_in_group("player")
	if p:
		Global.player_pos = p.global_position
	Global.last_world_scene = get_tree().current_scene.scene_file_path
	# Utilizziamo la transition o il cambio scena normale verso lo shop
	TransitionChangeManager.change_scene("res://Scenes/shop_scene.tscn")
