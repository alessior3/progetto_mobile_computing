extends Node2D

var outside = "res://Scenes/world.tscn"

func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "player":
		get_tree().change_scene_to_file(outside)

func change_scene():
	get_tree().change_scene_to_file(outside)
