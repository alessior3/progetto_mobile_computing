extends Node2D

@export_file("*.tscn") var inside_scene: String = "res://Scenes/inside_house6.tscn"

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
	Global.play_door_open()
	var p = get_tree().get_first_node_in_group("player")
	if p:
		Global.player_pos = p.global_position
	Global.last_world_scene = get_tree().current_scene.scene_file_path
	Global.from_house3_to_percorso = true
	if TransitionChangeManager:
		TransitionChangeManager.change_scene(inside_scene)
	else:
		get_tree().change_scene_to_file(inside_scene)
