extends Node2D

@onready var player = find_child("player", true, false)
@onready var spawn_point = $PlayerSpawnPoint

func _ready():
	await get_tree().process_frame
	
	if player:
		var target_pos = player.global_position
		
		if Global.from_grotta_to_percorso:
			if Global.player_pos != Vector2.ZERO:
				target_pos = Global.player_pos
				print("Player posizionato alla posizione di ingresso salvata (ritorno da Grotta1)")
			else:
				var exit_marker = find_child("UscitaGrotta", true, false)
				if exit_marker:
					target_pos = exit_marker.global_position
					print("Player posizionato su UscitaGrotta (ritorno da Grotta1)")
			
			Global.from_grotta_to_percorso = false
			Global.player_pos = Vector2.ZERO
		elif Global.from_house3_to_percorso:
			if Global.player_pos != Vector2.ZERO:
				target_pos = Global.player_pos
				print("Player posizionato alla posizione salvata (ritorno da inside_house3)")
			
			Global.from_house3_to_percorso = false
			Global.player_pos = Vector2.ZERO
		elif Global.from_villaggio2_to_percorso1:
			var exit_marker = find_child("UscitaPercorso1", true, false)
			if exit_marker:
				target_pos = exit_marker.global_position
				print("Player posizionato su UscitaPercorso1 (ritorno da Villaggio2)")
			Global.from_villaggio2_to_percorso1 = false
		elif spawn_point:
			target_pos = spawn_point.global_position
			print("Player forzato su PlayerSpawnPoint: ", spawn_point.global_position)
		
		# Forza la posizione per 5 frame consecutivi per vincere contro la fisica
		for i in range(5):
			player.global_position = target_pos
			player.position = target_pos
			await get_tree().physics_frame
		
		# Resetta la camera
		var camera = player.find_child("Camera2D", true, false)
		if camera:
			camera.reset_smoothing()
			camera.force_update_scroll()
