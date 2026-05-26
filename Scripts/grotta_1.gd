extends Node2D

@export var inside_scene: PackedScene
@onready var door_sprite = $DoorWay/Sprite2D

func _ready() -> void:
	pass

func _on_door_way_body_entered(body: Node2D) -> void:
	if body.name == "player":
		body.house = self

func _on_door_way_body_exited(body: Node2D) -> void:
	if body.name == "player":
		if body.house == self:
			body.house = null

func enter():
	Global.play_door_open()
	# --- LOGICA DI ACCESSO DUNGEON (Floppy Disk) ---
	var has_restored = false
	var has_corrupted = false
	
	for item in Global.persistent_items:
		if item and item.item_id == "restored_floppy":
			has_restored = true
			break
		if item and item.item_id == "corrupted_floppy":
			has_corrupted = true

	if not has_restored:
		if has_node("/root/DialogueManager"):
			if has_corrupted:
				Global.has_tried_cave = true
				DialogueManager.show_message([
					"SISTEMA: Supporto rilevato.",
					"ERRORE CRC: Settore 0 danneggiato.",
					"Accesso negato. Ripristino richiesto presso unità Mainframe."
				])
			else:
				DialogueManager.show_message([
					"SISTEMA: Inserire supporto di avvio per sbloccare l'ingresso.",
					"L'unità accetta Floppy Disk da 3.5 pollici."
				])
		return # Interrompiamo l'entrata se non ha il floppy corretto!

	# --- VECCHIA LOGICA DI ENTRATA (Se il floppy è OK) ---
	var target = inside_scene
	if not target:
		target = load("res://Scenes/dungeon_1.tscn")
		
	if target:
		# Rimuove l'immagine della porta chiusa per mostrare la grotta sotto
		if door_sprite:
			door_sprite.hide()
		# Attende un attimo per dare un effetto visivo di apertura
		await get_tree().create_timer(0.2).timeout
		
		# Salva la posizione e cambia scena
		if get_tree().current_scene.name == "Percorso1":
			Global.from_grotta_to_percorso = true
		
		Global.player_pos = $"../player".global_position if has_node("../player") else Vector2.ZERO
		if TransitionChangeManager:
			TransitionChangeManager.change_scene("res://Scenes/dungeon_1.tscn") # Forziamo il dungeon corretto
		else:
			get_tree().change_scene_to_packed(target)
