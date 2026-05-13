extends Area2D

@export var chest_id: String = "cassa_casa_1"
@export var chest_size: int = 15
@export var oggetto_iniziale: Resource = null
@export var is_locked: bool = false

@export_group("Loot Pool (Gambling)")
@export var use_loot_pool: bool = false
@export var loot_spawn_count: int = 1
@export var loot_pool_items: Array[InventoryItem] = []
@export var loot_pool_weights: Array[float] = []

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
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
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
		
		if use_loot_pool and loot_pool_items.size() > 0:
			print("DEBUG: Generazione loot casuale per la cassa ", chest_id)
			for i in range(min(loot_spawn_count, chest_size)):
				var random_item = _get_random_loot()
				if random_item:
					print("DEBUG: Slot ", i, " -> ", random_item.name if "name" in random_item else "Oggetto")
					chest_items[i] = random_item
		elif oggetto_iniziale != null:
			# Mettiamo l'oggetto nel primo slot (posizione 0)
			chest_items[0] = oggetto_iniziale
			
		Global.chests_data[chest_id] = chest_items

func _get_random_loot() -> InventoryItem:
	if loot_pool_items.is_empty() or loot_pool_weights.is_empty():
		return null
		
	var total_weight = 0.0
	# Usiamo la dimensione minima tra i due array per evitare errori se non sono lunghi uguali
	var size = min(loot_pool_items.size(), loot_pool_weights.size())
	
	for i in range(size):
		if loot_pool_weights[i] > 0:
			total_weight += loot_pool_weights[i]
			
	if total_weight <= 0:
		return null
		
	var roll = randf() * total_weight
	var current_sum = 0.0
	
	for i in range(size):
		if loot_pool_weights[i] > 0:
			current_sum += loot_pool_weights[i]
			if roll <= current_sum:
				return loot_pool_items[i]
				
	return null

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
		print("DEBUG: Interact premuto sulla cassa. Locked: ", is_locked)
		if is_locked:
			print("La cassa è bloccata!")
			return
		toggle_chest()

func unlock():
	print("DEBUG: Ricevuta chiamata unlock() sulla cassa.")
	if is_locked:
		is_locked = false
		print("Cassa sbloccata!")

func lock():
	print("DEBUG: Ricevuta chiamata lock() sulla cassa.")
	if not is_locked:
		is_locked = true
		print("Cassa di nuovo bloccata!")

func toggle_chest():
	print("DEBUG: Chiamata toggle_chest()")
	var chest_ui = get_tree().current_scene.get_node_or_null("ChestUI") 
	if not chest_ui:
		print("DEBUG: ERRORE! Nodo 'ChestUI' non trovato nella scena corrente.")
	var inv_ui = current_player.get_node_or_null("inventoryUI") if current_player else null
	
	if sprite.region_rect.position.x == x_chiusa:
		sprite.region_rect.position.x = x_aperta
		print("Cassa aperta visivamente!")
		
		# --- SUONO APERTURA QUI ---
		if has_node("OpenSound"):
			$OpenSound.play()
		# --------------------------
		
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
		
		# --- SUONO CHIUSURA QUI ---
		if has_node("CloseSound"):
			$CloseSound.play()
		# --------------------------
		
		# Chiudiamo la UI
		if chest_ui:
			chest_ui.close_chest_ui()
			
		# Chiudiamo lo zaino in automatico se stiamo chiudendo la cassa ed era rimasto aperto
		if inv_ui and inv_ui.visible:
			inv_ui.toggle()
