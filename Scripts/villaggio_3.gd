extends Node2D

@onready var player = find_child("player", true, false)
@onready var spawn_point = find_child("IngressoVillaggio3", true, false)

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	if player:
		var target_pos = player.global_position
		
		if Global.from_percorso2_to_villaggio3:
			if spawn_point:
				target_pos = spawn_point.global_position
				print("DEBUG: Spostamento su IngressoVillaggio3 (global_pos: ", target_pos, ")")
			Global.from_percorso2_to_villaggio3 = false
		
		# Forza la posizione per qualche frame
		for i in range(10):
			player.global_position = target_pos
			await get_tree().physics_frame
			
		# Resetta la camera
		var camera = player.find_child("Camera2D", true, false)
		if not camera:
			camera = player.find_child("playerCamera", true, false)
			
		if camera:
			camera.reset_smoothing()
			camera.force_update_scroll()
