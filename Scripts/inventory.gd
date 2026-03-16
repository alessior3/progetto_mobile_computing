extends Node
class_name Inventory

# SEGNALI
signal gold_changed(new_amount: int)

# RIFERIMENTI NODI (Resi sicuri per evitare crash)
@onready var inventory_ui: InventoryUI = $"../inventoryUI"
# get_node_or_null evita l'errore se lo sprite non esiste in una specifica scena
@onready var equipped_sprite: Sprite2D = get_node_or_null("../EquippedSprite") 

@export var on_screen_ui: OnScreenUi 

# PRELOAD DELLA SCENA DA DROPPARE (Verifica che il percorso sia corretto!)
const PICK_UP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")

# VARIABILI DATI
var items: Array[InventoryItem] = []
var gold: int = 0

func _ready() -> void:
	# 1. CARICAMENTO DATI: Riprendiamo tutto dal Global
	gold = Global.persistent_gold
	items = Global.persistent_items
	
	# 2. TEMPISTICA: Aspettiamo un frame per assicurarci che la UI sia pronta
	await get_tree().process_frame
	
	if on_screen_ui:
		# Colleghiamo il segnale per gestire i click sui quadratini a schermo
		if not on_screen_ui.request_unequip.is_connected(_on_unequip_item):
			on_screen_ui.request_unequip.connect(_on_unequip_item)
		
		# Ripristiniamo gli oggetti negli slot (mano, pozioni, cibo)
		_restore_equipment_ui()
		gold_changed.emit(gold)
	
	if inventory_ui:
		inventory_ui.update_slots(items)
	
	print("DEBUG (Inventory): Stato caricato e sincronizzato. Oro: ", gold)

# --- GESTIONE INPUT E RACCOLTA ---

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		if inventory_ui:
			inventory_ui.update_slots(items) 
			inventory_ui.toggle()

func add_item(item: InventoryItem, amount: int = 1) -> void:
	if item == null: return
	
	# Intercettazione Oro (Wallet)
	if item.name == "Gold Coin":
		gold += amount
		Global.persistent_gold = gold # Sincronizzazione persistente
		gold_changed.emit(gold)
		return 
	
	# Oggetti Standard
	item.stacks = amount
	items.append(item)
	Global.persistent_items = items # Sincronizzazione persistente
	
	if inventory_ui:
		inventory_ui.update_slots(items)

# --- LOGICA EQUIPAGGIAMENTO E DROP ---

func _on_slot_item_clicked(item: InventoryItem):
	if item == null: return
	
	# --- FIX: GESTIONE DELLO SCAMBIO (SWAP) ---
	var old_item: InventoryItem = null
	
	# Controlliamo cosa c'è attualmente equipaggiato in questo specifico slot
	match item.slot_type:
		"Hand": old_item = Global.persistent_hand
		"Potions": old_item = Global.persistent_potions
		"Food": old_item = Global.persistent_food
		
	# Se c'era già un oggetto, lo rimettiamo nello zaino prima di prendere il nuovo
	if old_item != null:
		items.append(old_item)
		print("DEBUG (Inventory): Scambiato ", old_item.name, " con ", item.name)
	# -----------------------------------------
	
	# 1. Aggiorna la UI a schermo e i dati persistenti
	if on_screen_ui:
		on_screen_ui.equip_item(item, item.slot_type)
		_save_equipment_to_global(item.slot_type, item)
	
	# 2. Gestione visuale sicura dello sprite
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.texture = item.texture
		equipped_sprite.show()
	
	# 3. Rimuove il NUOVO oggetto dallo zaino persistente
	items.erase(item)
	Global.persistent_items = items
	
	# 4. Aggiorna e CHIUDE l'inventario automaticamente
	if inventory_ui:
		inventory_ui.update_slots(items)
		if inventory_ui.visible:
			inventory_ui.toggle()

func _on_unequip_item(item: InventoryItem):
	if item == null: return
	
	# 1. Rimuove dai dati persistenti degli slot
	_save_equipment_to_global(item.slot_type, null)
	
	# 2. Riporta nello zaino persistente
	items.append(item)
	Global.persistent_items = items
	
	# 3. Gestione visuale sicura dello sprite
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.hide()
		
	if inventory_ui:
		inventory_ui.update_slots(items)

# NUOVA FUNZIONE: Droppa l'oggetto a terra con animazione di lancio
func drop_item(item_to_drop: InventoryItem):
	if item_to_drop == null: return
	
	items.erase(item_to_drop)
	Global.persistent_items = items
	
	# Istanzia l'oggetto
	var dropped_node = PICK_UP_ITEM_SCENE.instantiate()
	
	# --- FIX 1: Y-SORT E Z-INDEX ---
	dropped_node.z_index = -1
	dropped_node.y_sort_enabled = true
	
	# --- FIX 2: PARENTING PER Y-SORT ---
	# Lo aggiungiamo allo stesso padre del Player (il livello) per un Y-Sort perfetto
	var level_node = get_parent().get_parent()
	level_node.add_child(dropped_node)
	
	# Assegna i dati e resetta l'ID
	dropped_node.inventory_item = item_to_drop
	dropped_node.item_id = ""
	
	# --- FIX 3: CHIUDI L'INVENTARIO ---
	if inventory_ui and inventory_ui.visible:
		inventory_ui.toggle()
	
	# --- EFFETTO DI LANCIO (TWEEN) ---
	var start_pos = get_parent().global_position
	var random_offset = Vector2(randf_range(-35.0, 35.0), randf_range(10.0, 30.0))
	var end_pos = start_pos + random_offset
	
	dropped_node.global_position = start_pos
	
	var tween_x = dropped_node.create_tween()
	tween_x.tween_property(dropped_node, "global_position:x", end_pos.x, 0.4)
	
	var tween_y = dropped_node.create_tween()
	var peak_y = min(start_pos.y, end_pos.y) - 25
	
	tween_y.tween_property(dropped_node, "global_position:y", peak_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(dropped_node, "global_position:y", end_pos.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	if inventory_ui:
		inventory_ui.update_slots(items)
		
	print("DEBUG (Inventory): Droppato nel mondo con animazione: ", item_to_drop.name)

func _restore_equipment_ui():
	# Mappa degli oggetti salvati nel Global
	var slots = {
		"Hand": Global.persistent_hand,
		"Potions": Global.persistent_potions,
		"Food": Global.persistent_food
	}
	
	for slot_type in slots:
		var item = slots[slot_type]
		if item:
			on_screen_ui.equip_item(item, slot_type)
			# Ripristino visuale dell'arma se presente
			if slot_type == "Hand" and equipped_sprite:
				equipped_sprite.texture = item.texture
				equipped_sprite.show()

func _save_equipment_to_global(type: String, item: InventoryItem):
	# Aggiorna il Singleton per la persistenza tra scene
	match type:
		"Hand": Global.persistent_hand = item
		"Potions": Global.persistent_potions = item
		"Food": Global.persistent_food = item

func has_gold(amount: int) -> bool:
	return gold >= amount

func remove_gold(amount: int) -> void:
	gold -= amount
	Global.persistent_gold = gold
	gold_changed.emit(gold)
	
# ==========================================
# RACCOLTA INTELLIGENTE (SLOT SEPARATI)
# ==========================================
func smart_add_pickup(item: InventoryItem, amount: int):
	# Controlliamo PRIMA se possiamo equipaggiarlo subito nella UI a schermo
	if on_screen_ui != null:
		
		# Se è un'arma e abbiamo le mani libere
		if item.get("is_weapon") == true and Global.persistent_hand == null:
			item.stacks = amount # Impostiamo la quantità raccolta
			on_screen_ui.equip_item(item, "Hand")
			Global.persistent_hand = item
			print("Auto-equipaggiato in mano (non nello zaino): ", item.name)
			return # <-- FONDAMENTALE: Ferma la funzione qui!

		# Se è cibo/consumabile e non abbiamo niente nello slot Food
		elif item.get("is_consumable") == true and Global.persistent_food == null:
			item.stacks = amount # Impostiamo la quantità raccolta
			on_screen_ui.equip_item(item, "Food")
			Global.persistent_food = item
			print("Auto-equipaggiato nel cibo (non nello zaino): ", item.name)
			return # <-- FONDAMENTALE: Ferma la funzione qui!

	# Se arriviamo a questo punto, significa che gli slot rapidi erano pieni 
	# oppure l'oggetto non era né un'arma né cibo (es. semi, legno, ecc.).
	# Solo ora lo aggiungiamo fisicamente allo zaino:
	add_item(item, amount)
