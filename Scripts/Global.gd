extends Node

var player_pos : Vector2
var current_username = "Giocatore Sconosciuto"

# Diciamo a Godot dove creare il file di salvataggio nel computer
var save_path = "user://savegame.save"

# --- 1. FUNZIONE CHE CREIAMO PER SALVARE ---
func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var data = {
		"nome": current_username,
		"posizione": player_pos
	}
	file.store_var(data)
	file.close()
	print("Partita Salvata con successo!")

# --- 2. FUNZIONE CHE CREIAMO PER CARICARE ---
func load_game() -> bool:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		current_username = data["nome"]
		player_pos = data["posizione"]
		print("Partita Caricata! Bentornato ", current_username)
		return true
	else:
		print("Nessun salvataggio trovato!")
		return false
