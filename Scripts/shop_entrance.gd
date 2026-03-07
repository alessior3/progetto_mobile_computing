extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Controlliamo che sia effettivamente il giocatore a entrare
	# Usiamo sia 'player' che 'Player' per essere sicuri al 100%
	if body.name == "player" or body.name == "Player":
		# Salviamo la posizione esterna di entrata così al ritorno
		# il mondo può riposizionare il giocatore dove era.
		Global.player_pos = body.global_position
		TransitionChangeManager.change_scene("res://Scenes/shop_scene.tscn")
