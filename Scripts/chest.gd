extends Area2D

@export var chest_id: String = "cassa_casa_1"
@export var chest_size: int = 15

# Coordinate spritesheet
@export var x_chiusa: float = 0.0
@export var x_aperta: float = 16.0

var player_in_range: bool = false
var current_player: CharacterBody2D = null
var chest_items: Array = []

@onready var sprite = $Sprite2D

func _ready() -> void:
	print("Chest pronta")
	sprite.region_enabled = true
	sprite.region_rect = Rect2(x_chiusa, 0, 16, 14)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Inizializzazione inventario cassa
	if Global.chests_data.has(chest_id):
		chest_items = Global.chests_data[chest_id]
		
		# --- NOVITÀ: AGGIORNAMENTO AUTOMATICO ---
		# Se nel frattempo abbiamo ingrandito la cassa nell'editor, aggiungiamo gli slot mancanti
		if chest_items.size() < chest_size:
			var slot_mancanti = chest_size - chest_items.size()
			for i in range(slot_mancanti):
				chest_items.append(null)
		# ----------------------------------------
		
	else:
		chest_items.resize(chest_size)
		chest_items.fill(null)
		Global.chests_data[chest_id] = chest_items

func _on_body_entered(body: Node2D) -> void:
	print("Qualcosa è entrato nell'area:", body.name)
	if body.is_in_group("player"):
		print("Player vicino alla cassa")
		player_in_range = true
		current_player = body
		
		if body.has_node("Key"):
			body.get_node("Key").show()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		
		# SICUREZZA: Se ti allontani dalla cassa mentre è aperta, si chiude da sola!
		if sprite.region_rect.position.x == x_aperta:
			toggle_chest()
			
		player_in_range = false
		current_player = null
		
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

		# Chiude visivamente la cassa
		sprite.region_rect.position.x = x_chiusa

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		toggle_chest()

func toggle_chest():
	var chest_ui = get_tree().current_scene.get_node_or_null("ChestUI") 
	var inv_ui = current_player.get_node_or_null("inventoryUI") if current_player else null
	
	if sprite.region_rect.position.x == x_chiusa:
		sprite.region_rect.position.x = x_aperta
		print("Cassa aperta visivamente!")
		
		# --- LA MODIFICA CHIAVE: Rinfresca la memoria prima di aprire! ---
		if Global.chests_data.has(chest_id):
			chest_items = Global.chests_data[chest_id]
		# -----------------------------------------------------------------
		
		# Apriamo la UI e passiamo gli oggetti, l'id e se stessa
		if chest_ui:
			chest_ui.open_chest_ui(chest_items, chest_id, self)
			
	else:
		sprite.region_rect.position.x = x_chiusa
		print("Cassa chiusa visivamente!")
		
		# Chiudiamo la UI
		if chest_ui:
			chest_ui.close_chest_ui()
			
		# Chiudiamo lo zaino in automatico se stiamo chiudendo la cassa ed era rimasto aperto
		if inv_ui and inv_ui.visible:
			inv_ui.toggle()
