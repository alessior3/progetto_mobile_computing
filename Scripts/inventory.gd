extends Node
class_name Inventory

@onready var inventory_ui: InventoryUI = $"../inventoryUI"
# Assicurati di avere questo nodo EquippedSprite nel Player se vuoi l'arma visibile
@onready var equipped_sprite: Sprite2D = $"../EquippedSprite" 

@export var on_screen_ui: OnScreenUi 

var items: Array[InventoryItem] = []

func _ready() -> void:
	# Colleghiamo l'interfaccia a schermo all'inventario all'avvio
	if on_screen_ui:
		on_screen_ui.request_unequip.connect(_on_unequip_item)

# inventory.gd

# QUESTA È QUELLA CHE MANCAVA (Equip)
func _on_slot_item_clicked(item: InventoryItem):
	if item == null: return
	
	# 1. Mandiamo l'oggetto alla barra rapida (UI a schermo)
	if on_screen_ui:
		on_screen_ui.equip_item(item, item.slot_type)
	
	# 2. Se è un'arma, mostriamola fisicamente sul player
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.texture = item.texture
		equipped_sprite.show()
	
	# 3. Lo togliamo dallo zaino e aggiorniamo la griglia
	items.erase(item)
	if inventory_ui:
		inventory_ui.update_slots(items)
	
	print("DEBUG (Inventory): ", item.name, " equipaggiato correttamente.")

# QUESTA È QUELLA PER TORNARE INDIETRO (Unequip)
func _on_unequip_item(item: InventoryItem):
	items.append(item)
	
	if item.slot_type == "Hand" and equipped_sprite:
		equipped_sprite.hide()
		
	if inventory_ui:
		inventory_ui.update_slots(items)
	
	print("DEBUG (Inventory): ", item.name, " tornato nello zaino!")
# ... (tieni le tue funzioni add_item e _input come sono già)
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		if inventory_ui:
			# Prima aggiorniamo le icone, poi mostriamo la UI
			inventory_ui.update_slots(items) 
			inventory_ui.toggle()
			print("DEBUG: Slot aggiornati con ", items.size(), " oggetti.")
		else:
			print("ERRORE (Inventory): inventory_ui non trovato nel percorso specificato!")

func add_item(item: InventoryItem, amount: int=1) -> void:
	if item:
		item.stack=amount
		items.append(item)
		print("DEBUG (Inventory): Aggiunto ", item.name, " x", amount)
		print("DEBUG (Inventory): Totale oggetti nell'array: ", items.size())
		
