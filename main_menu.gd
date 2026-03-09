extends Control

# Prendiamo i riferimenti alle caselle di testo del login
@onready var username_input = $VBoxContainer/UsernameInput
@onready var password_input = $VBoxContainer/PasswordInput

# --- FUNZIONI DEI BOTTONI ---

func _on_btn_login_pressed() -> void:
	var user = username_input.text
	var password = password_input.text
	
	if user == "" or password == "":
		print("Errore: Inserisci username e password!")
		return
		
	print("Tentativo di login per: ", user)
	# Qui in futuro collegheremo il gioco a un database online!

func _on_btn_inizia_pressed() -> void:
	print("Inizio nuova partita!")
	# Sostituisci "res://Scenes/world.tscn" con il percorso esatto della tua scena di gioco
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_btn_carica_pressed() -> void:
	print("STO PROVANDO A CARICARE LA PARTITA!") # <-- Aggiungi questo!
	var success = SaveManager.load_game()

func _on_btn_quit_pressed() -> void:
	print("Uscita dal gioco...")
	get_tree().quit()
