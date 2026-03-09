extends CanvasLayer
class_name InventoryUI

# RIFERIMENTI
@onready var grid_container: GridContainer = %GridContainer
const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")

@export var inventory: Inventory 

@export var size: int = 16
@export var columns: int = 4

func _ready() -> void:    
	print("DEBUG (UI): Inizializzazione InventoryUI. Colonne: ", columns)
	grid_container.columns = columns
	
	for i in size:
		var inventory_slot = INVENTORY_SLOT_SCENE.instantiate()
		grid_container.add_child(inventory_slot)
	
	hide()
	print("DEBUG (UI): Generati correttamente ", grid_container.get_child_count(), " slot.")

func toggle():
	visible = !visible
	if visible and inventory:
		update_slots(inventory.items)

func update_slots(items_list: Array[InventoryItem]):
	var slots = grid_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		if i < items_list.size():
			var current_item = items_list[i]
			slot.add_item(current_item)
			
			# Connessione Equip
			if not slot.slot_clicked.is_connected(_on_slot_item_clicked):
				slot.slot_clicked.connect(_on_slot_item_clicked)
				
			# Connessione Drop
			if not slot.item_dropped.is_connected(_on_slot_item_dropped):
				slot.item_dropped.connect(_on_slot_item_dropped)
		else:
			slot.add_item(null)

func _on_slot_item_clicked(item: InventoryItem):
	if inventory:
		inventory._on_slot_item_clicked(item)

# NUOVA FUNZIONE: Invia la richiesta di drop all'inventario
func _on_slot_item_dropped(item: InventoryItem):
	if inventory:
		inventory.drop_item(item)
