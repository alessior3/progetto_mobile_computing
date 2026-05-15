extends Node2D

func _ready():
	# Forziamo l'animazione della camminata appena si carica la scena
	if $FintoPlayer.has_method("play"):
		$FintoPlayer.play("walk_up")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "scorrimento_finale":
		
		# Salviamo il gioco spostando il player all'inizio (mantenedo il loot)
		save_post_game_state()
		
		# Aspettiamo 2 secondi e torniamo al menu principale
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func save_post_game_state():
	# 1. Definiamo la mappa iniziale in cui il player si sveglierà
	var world_scene_path = "res://Scenes/world.tscn"
	
	# 2. Le coordinate esatte del tuo PlayerSpawnPoint in world.tscn
	var start_pos = Vector2(361.3, 1304.3)
	
	# 3. Chiamiamo la nuova funzione creata nell'Autoload SaveManager
	SaveManager.save_new_game_plus(world_scene_path, start_pos)
	
	print("Partita salvata post-crediti! Il player ha mantenuto l'equipaggiamento e ripartirà dall'inizio.")
