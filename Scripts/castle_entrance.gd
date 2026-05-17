extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		# Salviamo la posizione per il ritorno
		Global.player_pos = body.global_position
		
		if TransitionChangeManager:
			TransitionChangeManager.change_scene("res://Scenes/inside_castle.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/inside_castle.tscn")
