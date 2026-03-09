extends Node

const SAVE_FILE = "user://savegame.dat"

# AGGIUNGI QUESTE DUE VARIABILI IN CIMA:
var is_loading_game: bool = false
var loaded_position: Vector2 = Vector2.ZERO

func save_game():
	var player = get_tree().get_first_node_in_group("player")
	var current_scene = get_tree().current_scene.scene_file_path
	
	var data_to_save = {
		"saved_scene": current_scene,
		"player_x": 0.0,
		"player_y": 0.0
	}
	
	if player:
		data_to_save["player_x"] = player.global_position.x
		data_to_save["player_y"] = player.global_position.y
		# STAMPIAMO LE COORDINATE PER ESSERE SICURI CHE NON SIANO ZERO!
		print("Salvo posizione: X:", data_to_save["player_x"], " Y:", data_to_save["player_y"])
		
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_var(data_to_save)
	file.close()
	print("Partita Salvata con successo!")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		return false
		
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var saved_data = file.get_var()
	file.close()
	
	# SALVIAMO LE COORDINATE NELLA NUOVA VARIABILE
	loaded_position = Vector2(saved_data["player_x"], saved_data["player_y"])
	is_loading_game = true # Diciamo al gioco "Ehi, stiamo caricando!"
	
	TransitionChangeManager.change_scene(saved_data["saved_scene"])
	get_tree().paused = false 
	return true
