extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		Global.play_door_open()
		# Salviamo la posizione per il ritorno
		Global.player_pos = body.global_position
		Global.last_world_scene = get_tree().current_scene.scene_file_path
		
		if TransitionChangeManager:
			TransitionChangeManager.change_scene("res://Scenes/inside_castle.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/inside_castle.tscn")
