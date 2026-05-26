extends Node2D

@onready var player = $player
@onready var player_spawn_point: Marker2D = $PlayerSpawnPoint

func _ready():
	if not has_node("GameSound"):
		var bg_music = AudioStreamPlayer.new()
		bg_music.name = "GameSound"
		bg_music.stream = preload("res://Sounds/game_sound.wav")
		bg_music.autoplay = true
		bg_music.volume_db = -25.0
		add_child(bg_music)
		
	if SaveManager.is_loading_game:
		return

	# Se torniamo dal percorso, cerchiamo il marker specifico PlayerSpawnPoint2
	if Global.from_percorso:
		var spawn2 = find_child("PlayerSpawnPoint2", true, false)
		if spawn2:
			player.global_position = spawn2.global_position
			player.current_dir = "up" # Lo facciamo guardare in su
			Global.set("player_facing_dir", "up") # Evitiamo che player.gd lo rimetta verso il basso!
			player.play_anim(0)
			print("Player posizionato su PlayerSpawnPoint2 (ritorno da Percorso1)")
		else:
			# Se non esiste, usiamo la posizione salvata o il default
			_handle_standard_positioning()
		
		# Resettiamo i flag e le posizioni per evitare conflitti
		Global.from_percorso = false
		Global.player_pos = Vector2.ZERO
	else:
		_handle_standard_positioning()

func _handle_standard_positioning():
	if Global.player_pos != Vector2.ZERO:
		player.global_position = Global.player_pos
	else:
		player.global_position = player_spawn_point.global_position
