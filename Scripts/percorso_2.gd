extends Node2D

@onready var player = find_child("player", true, false)
@onready var spawn_point_ingresso = find_child("SpawnPlayerIngresso", true, false)
@onready var spawn_point_uscita = find_child("SpawnPlayerUscita", true, false)

func _ready():
	if not has_node("GameSound"):
		var bg_music = AudioStreamPlayer.new()
		bg_music.name = "GameSound"
		bg_music.stream = preload("res://Sounds/game_sound.wav")
		bg_music.autoplay = true
		bg_music.volume_db = -25.0
		add_child(bg_music)
		
	await get_tree().process_frame
	await get_tree().process_frame
	
	if player:
		var target_pos = player.global_position
		
		if Global.from_villaggio2_to_percorso2:
			if spawn_point_ingresso:
				target_pos = spawn_point_ingresso.global_position
				print("DEBUG: Spostamento su SpawnPlayerIngresso (global_pos: ", target_pos, ")")
			Global.from_villaggio2_to_percorso2 = false
		elif Global.from_villaggio3_to_percorso2:
			if spawn_point_uscita:
				target_pos = spawn_point_uscita.global_position
				print("DEBUG: Spostamento su SpawnPlayerUscita (global_pos: ", target_pos, ")")
			Global.from_villaggio3_to_percorso2 = false
		
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
