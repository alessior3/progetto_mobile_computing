extends CanvasLayer

class_name InventoryUI

@onready var grid_container:GridContainer=%GridContainer
const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")
@export var inventory: Inventory

@export var size: int=16
@export var columns: int=4

# ... (variabili iniziali)

func _ready() -> void:	
	print("DEBUG (UI): Inizializzazione InventoryUI. Colonne: ", columns, " Slot totali: ", size)
	grid_container.columns = columns
	
	for i in size:
		var inventory_slot = INVENTORY_SLOT_SCENE.instantiate()
		grid_container.add_child(inventory_slot)
		if inventory: 
			inventory_slot.item_clicked.connect(inventory._on_slot_item_clicked)
	
	print("DEBUG (UI): Generati correttamente ", grid_container.get_child_count(), " slot.")
	
func toggle():
	visible=!visible
	
	# inventory_ui.gd
func update_slots(items_list: Array[InventoryItem]):
	# Prendiamo tutti gli slot figli del GridContainer
	var slots = grid_container.get_children()
	
	for i in range(slots.size()):
		if i < items_list.size():
			# Se abbiamo un oggetto per questa posizione, mostralo
			slots[i].display_item(items_list[i])
		else:
			# Altrimenti lascia lo slot vuoto
			slots[i].display_item(null)
