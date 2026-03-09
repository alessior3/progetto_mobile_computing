extends Node
class_name Inventory

# SEGNALI
signal gold_changed(new_amount: int) # Per avvisare la UI quando il portafoglio cambia

# RIFERIMENTI NODI
@onready var inventory_ui: InventoryUI = $"../inventoryUI"
@onready var equipped_sprite: Sprite2D = $"../EquippedSprite" # Figlio del Player

@export var on_screen_ui: OnScreenUi 

# VARIABILI DATI
var items: Array[InventoryItem] = []
var gold: int = 0 # Il nostro portafoglio separato

func _ready() -> void:
	# Colleghiamo l'interfaccia a schermo per gestire l'unequip
	if on_screen_ui:
		on_screen_ui.request_unequip.connect(_on_unequip_item)
		# Sincronizziamo il valore iniziale dell'oro all'avvio
		gold_changed.emit(gold)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		if inventory_ui:
			inventory_ui.update_slots(items) 
			inventory_ui.toggle()
			print("DEBUG (Inventory): Inventario aperto. Oggetti: ", items.size(), " | Oro: ", gold)
		else:
			print("ERRORE: inventory_ui non trovato!")

# LOGICA RACCOLTA (WALLET INTERCEPTOR)
func add_item(item: InventoryItem, amount: int = 1) -> void:
	if item == null: return
	
	# CONTROLLO PORTAFOGLIO: se l'oggetto si chiama "Gold Coin", non occupa slot
	if item.name == "Gold Coin":
		gold += amount
		gold_changed.emit(gold) # Avvisiamo la OnScreenUI
		print("DEBUG (Portafoglio): +", amount, " monete raccolte. Totale attuale: ", gold)
		return # Interrompiamo qui: la moneta non finisce nell'array 'items'
	
	# LOGICA STANDARD: per tutti gli altri oggetti
	item.stacks = amount
	items.append(item)
	
	if inventory_ui:
		inventory_ui.update_slots(items)
	
	print("DEBUG (Inventory): Aggiunto ", item.name, " x", amount, " allo zaino.")

# LOGICA EQUIPAGGIAMENTO
func _on_slot_item_clicked(item: InventoryItem):
	if item == null: return
	
	# 1. Mandiamo alla barra rapida
	if on_screen_ui:
		on_screen_ui.equip_item(item, item.slot_type)
	
	# 2. Visualizzazione fisica sul Player
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.texture = item.texture
		equipped_sprite.show()
	
	# 3. Rimozione dallo zaino (SPOSTAMENTO)
	items.erase(item)
	if inventory_ui:
		inventory_ui.update_slots(items)
	
	print("DEBUG (Inventory): ", item.name, " spostato dallo zaino all'equipaggiamento.")

# LOGICA RIMOZIONE EQUIP (UNEQUIP)
func _on_unequip_item(item: InventoryItem):
	if item == null: return
	
	# 1. Torna nell'array dello zaino
	items.append(item)
	
	# 2. Nascondiamo l'arma fisica se necessario
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.hide()
		
	# 3. Aggiorniamo la griglia dell'inventario
	if inventory_ui:
		inventory_ui.update_slots(items)
	
	print("DEBUG (Inventory): ", item.name, " tolto dall'equip e rimesso nello zaino.")

# FUNZIONI PER IL MERCANTE (SHOPPING)
func has_gold(amount: int) -> bool:
	return gold >= amount

func remove_gold(amount: int) -> void:
	gold -= amount
	gold_changed.emit(gold) # Aggiorniamo la UI dopo la spesa
	print("DEBUG (Portafoglio): Pagati ", amount, " monete. Oro rimanente: ", gold)
