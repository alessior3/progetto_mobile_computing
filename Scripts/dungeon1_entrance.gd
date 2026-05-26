extends Area2D

# Puoi cambiare la scena di destinazione comodamente dall'Inspector
@export var destination_scene: String = "res://Scenes/dungeon_1.tscn"

var player_in_range: bool = false
var current_player: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print("Qualcosa è entrato nell'area: ", body.name) # AGGIUNGI QUESTA RIGA
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		
		# Mostra l'animazione del tasto sul Player
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		
		# Nasconde il tasto quando ti allontani
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").stop()

func _input(event: InputEvent) -> void:
	# Se il giocatore è nell'area e preme il tasto di interazione
	if player_in_range and event.is_action_pressed("interact"):
		enter_dungeon()

func enter_dungeon() -> void:
	# Controlliamo se il giocatore ha il floppy giusto nell'inventario persistente
	var has_restored = false
	var has_corrupted = false
	
	for item in Global.persistent_items:
		if item and item.item_id == "restored_floppy":
			has_restored = true
			break
		if item and item.item_id == "corrupted_floppy":
			has_corrupted = true

	if has_restored:
		_perform_transition()
	elif has_corrupted:
		Global.has_tried_cave = true
		if has_node("/root/DialogueManager"):
			DialogueManager.show_message([
				"SISTEMA: Supporto rilevato.",
				"ERRORE CRC: Settori danneggiati nel settore 0.",
				"Accesso negato. Ripristino richiesto presso il Mainframe."
			])
	else:
		if has_node("/root/DialogueManager"):
			DialogueManager.show_message([
				"SISTEMA: Inserire supporto di avvio per sbloccare l'ingresso.",
				"L'unità accetta Floppy Disk da 3.5 pollici."
			])

func _perform_transition() -> void:
	Global.play_door_open()
	print("DEBUG (Mondo): Salvataggio stato in corso...")
	Global.save_game() 
	
	if current_player and current_player.has_node("Key"): 
		current_player.get_node("Key").hide()
	
	Global.player_facing_dir = "up"
	
	print("DEBUG (Mondo): Caricamento scena: ", destination_scene)
	TransitionChangeManager.change_scene(destination_scene)
