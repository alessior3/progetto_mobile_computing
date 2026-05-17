extends Area2D

@export var restored_floppy_res: Resource = preload("res://Resources/FloppyDisk/restored_floppy.tres")
@export var restore_time: float = 10.0

var player_in_range: bool = false
var current_player: Player = null
var is_restoring: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		current_player = body
		if body.has_node("Key"): body.get_node("Key").show()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		current_player = null
		if body.has_node("Key"): body.get_node("Key").hide()
		if is_restoring:
			stop_restoration()

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not is_restoring:
		check_and_start_restore()

func check_and_start_restore():
	if not Global.has_paid_treasurer:
		DialogueManager.show_message("ACCESSO NEGATO: Questo supercomputer è bloccato da password. Parla con Marcus Byte per sbloccarlo!", "Supercomputer")
		return

	var corrupted_item = null
	for item in Global.persistent_items:
		if item and item.item_id == "corrupted_floppy":
			corrupted_item = item
			break
	
	if corrupted_item:
		start_restoration()
	else:
		DialogueManager.show_message("ERRORE: Inserisci il Floppy Disk Corrotto nello slot del lettore floppy per iniziare il ripristino.", "Supercomputer")

func start_restoration():
	is_restoring = true
	DialogueManager.show_message("RIPRISTINO IN CORSO: Rimanere fermi davanti al computer! Tempo stimato: 10 secondi. ATTENZIONE: Il computer sta scaldando come un dannato!", "Supercomputer")
	
	# Qui potresti attivare una barra di caricamento sulla UI del player
	await get_tree().create_timer(restore_time).timeout
	
	if is_restoring:
		complete_restoration()

func stop_restoration():
	is_restoring = false
	DialogueManager.show_message("ERRORE: Connessione interrotta! Ti sei allontanato dal computer prima che il ripristino fosse completato.", "Supercomputer")

func complete_restoration():
	# Sostituiamo l'oggetto nell'inventario
	for i in range(Global.persistent_items.size()):
		if Global.persistent_items[i] and Global.persistent_items[i].item_id == "corrupted_floppy":
			Global.persistent_items[i] = restored_floppy_res
			break
	
	is_restoring = false
	DialogueManager.show_message("RIPRISTINO COMPLETATO: I settori danneggiati del Floppy Disk sono stati ripristinati correttamente! Ritira il supporto.", "Supercomputer")
	# Notifica il sistema UI se necessario
	if current_player and current_player.inventory:
		current_player.inventory.inventory_ui.update_slots(Global.persistent_items)
