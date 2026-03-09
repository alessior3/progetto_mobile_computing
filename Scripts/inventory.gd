extends Node
class_name Inventory

# SEGNALI
signal gold_changed(new_amount: int)

# RIFERIMENTI NODI (Resi sicuri per evitare crash)
@onready var inventory_ui: InventoryUI = $"../inventoryUI"
# get_node_or_null evita l'errore se lo sprite non esiste in una specifica scena
@onready var equipped_sprite: Sprite2D = get_node_or_null("../EquippedSprite") 

@export var on_screen_ui: OnScreenUi 

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

# --- LOGICA EQUIPAGGIAMENTO (Equip/Unequip) ---

func _on_slot_item_clicked(item: InventoryItem):
	if item == null: return
	
	# 1. Aggiorna la UI a schermo e i dati persistenti
	if on_screen_ui:
		on_screen_ui.equip_item(item, item.slot_type)
		_save_equipment_to_global(item.slot_type, item)
	
	# 2. Gestione visuale sicura dello sprite
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.texture = item.texture
		equipped_sprite.show()
	
	# 3. Rimuove dallo zaino persistente
	items.erase(item)
	Global.persistent_items = items
	
	if inventory_ui:
		inventory_ui.update_slots(items)

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

# --- FUNZIONI DI SUPPORTO (Sincronizzazione) ---

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
