extends CanvasLayer

func _ready() -> void:
	# Il menu deve essere invisibile quando inizia il gioco
	hide()

func _input(event: InputEvent) -> void:
	# Controlla se premiamo il tasto Esc (che abbiamo chiamato "pause")
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	# Inverte lo stato della pausa: se è in pausa la toglie, se non lo è la mette
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

func _on_resume_button_pressed() -> void:
	# Togliamo la pausa simulando la funzione di sopra
	toggle_pause()

func _on_quit_button_pressed() -> void:
	# FONDAMENTALE: Togli la pausa prima di cambiare scena, altrimenti il main menu sarà bloccato!
	get_tree().paused = false
	
	# Inserisci qui il percorso esatto del tuo Main Menu (controlla che sia scritto giusto)
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
