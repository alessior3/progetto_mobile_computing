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
	if username_input.text == "":
		Global.current_username = "Eroe Senza Nome"
	else:
		Global.current_username = username_input.text
		
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_btn_carica_pressed() -> void:
	print("Caricamento partita in corso...")
	# Proviamo a caricare. Se la funzione ci restituisce "true" (Vero), avviamo il gioco!
	if Global.load_game() == true:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")
	else:
		print("Devi prima iniziare una nuova partita per poterla salvare!")

func _on_btn_quit_pressed() -> void:
	print("Uscita dal gioco...")
	get_tree().quit()
