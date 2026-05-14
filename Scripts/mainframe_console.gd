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
	var corrupted_item = null
	for item in Global.persistent_items:
		if item and item.item_id == "corrupted_floppy":
			corrupted_item = item
			break
	
	if corrupted_item:
		start_restoration()
	else:
		print("DEBUG (Mainframe): Nessun floppy corrotto rilevato. Inserire supporto.")

func start_restoration():
	is_restoring = true
	print("DEBUG (Mainframe): Avvio ripristino settori danneggiati... NON USCIRE DALLA STANZA!")
	
	# Qui potresti attivare una barra di caricamento sulla UI del player
	await get_tree().create_timer(restore_time).timeout
	
	if is_restoring:
		complete_restoration()

func stop_restoration():
	is_restoring = false
	print("DEBUG (Mainframe): Connessione interrotta! Ripristino fallito.")

func complete_restoration():
	# Sostituiamo l'oggetto nell'inventario
	for i in range(Global.persistent_items.size()):
		if Global.persistent_items[i] and Global.persistent_items[i].item_id == "corrupted_floppy":
			Global.persistent_items[i] = restored_floppy_res
			break
	
	is_restoring = false
	print("DEBUG (Mainframe): Ripristino completato! Ritirare il Floppy Ripristinato.")
	# Notifica il sistema UI se necessario
	if current_player and current_player.inventory:
		current_player.inventory.inventory_ui.update_slots(Global.persistent_items)
