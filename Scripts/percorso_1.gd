extends Node2D

@onready var player = find_child("player", true, false)
@onready var spawn_point = $PlayerSpawnPoint

func _ready():
	# Aspettiamo un frame per assicurarci che il player sia stato inizializzato
	await get_tree().process_frame
	
	if player and spawn_point:
		# Forza la posizione globale del player sul marker di spawn
		player.global_position = spawn_point.global_position
		print("Player forzato su PlayerSpawnPoint: ", spawn_point.global_position)
		
		# Resetta la camera
		var camera = player.find_child("Camera2D", true, false)
		if camera:
			camera.reset_smoothing()
			camera.force_update_scroll()
