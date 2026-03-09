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



func _on_btn_quit_pressed() -> void:
	print("Uscita dal gioco...")
	get_tree().quit()
	
	
func _on_btn_carica_pressed() -> void:
	# Diciamo al SaveManager di provare a caricare la partita
	var success = SaveManager.load_game()
	
	# Se success è "false" (cioè non c'è nessun salvataggio)
	if not success:
			print("Nessun salvataggio trovato! Inizia una nuova partita.")
			# Qui in futuro potresti far apparire un testo a schermo che avvisa il giocatore
