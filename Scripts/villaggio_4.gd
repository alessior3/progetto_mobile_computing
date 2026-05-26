extends Node2D

@onready var player = find_child("player", true, false)
@onready var spawn_point = find_child("IngressoVillaggio3", true, false)

func _ready():
	# Verifichiamo subito all'inizio (al frame 0) se il player sta uscendo da una casa.
	# Questo perché player.gd azzera Global.player_pos nel suo _ready (dopo un frame).
	var was_exiting_house = (Global.player_pos != Vector2.ZERO and (get_tree().current_scene.scene_file_path == Global.last_world_scene or get_tree().current_scene.name == "world"))
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Se il player sta uscendo da una casa, lasciamo che il sistema delle porte gestisca il posizionamento.
	# Altrimenti (ad esempio se arriva dal percorso adiacente), lo posizioniamo sull'ingresso.
	if player and spawn_point and not was_exiting_house:
		var target_pos = spawn_point.global_position
		print("DEBUG Villaggio4: Posizionamento player su IngressoVillaggio3: ", target_pos)
		
		# Forza la posizione per qualche frame per stabilizzare fisica e telecamera
		for i in range(10):
			player.global_position = target_pos
			await get_tree().physics_frame
