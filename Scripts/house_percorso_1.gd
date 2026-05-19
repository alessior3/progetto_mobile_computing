extends Node2D

@onready var player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null

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
	if player:
		Global.player_pos = player.global_position
	Global.from_house3_to_percorso = true
	if TransitionChangeManager:
		TransitionChangeManager.change_scene("res://Scenes/inside_house3.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/inside_house3.tscn")
