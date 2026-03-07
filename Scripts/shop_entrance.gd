extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Controlliamo che sia effettivamente il giocatore a entrare
	# Usiamo sia 'player' che 'Player' per essere sicuri al 100%
	if body.name == "player" or body.name == "Player":
		TransitionChangeManager.player_spawn_position = Vector2(0,0)
		TransitionChangeManager.change_scene("res://Scenes/shop_scene.tscn")
