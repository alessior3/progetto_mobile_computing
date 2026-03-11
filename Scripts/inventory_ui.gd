extends CanvasLayer
class_name InventoryUI

# RIFERIMENTI
@onready var grid_container: GridContainer = %GridContainer
const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")

@export var inventory: Inventory 

@export var size: int = 16
@export var columns: int = 4

@onready var main_panel = $MarginContainer 
var posizione_centrale_y: float = 0.0

func _ready() -> void:    
	print("DEBUG (UI): Inizializzazione InventoryUI. Colonne: ", columns)
	grid_container.columns = columns
	
	for i in size:
		var inventory_slot = INVENTORY_SLOT_SCENE.instantiate()
		grid_container.add_child(inventory_slot)
	
	hide()
	print("DEBUG (UI): Generati correttamente ", grid_container.get_child_count(), " slot.")

	await get_tree().process_frame
	if main_panel:
		posizione_centrale_y = main_panel.position.y

func toggle():
	visible = !visible
	if visible and inventory:
		update_slots(inventory.items)
		if main_panel:
			main_panel.position.y = posizione_centrale_y

func update_slots(items_list: Array[InventoryItem]):
	var slots = grid_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		if i < items_list.size():
			var current_item = items_list[i]
			slot.add_item(current_item)
			
			if not slot.slot_clicked.is_connected(_on_slot_item_clicked):
				slot.slot_clicked.connect(_on_slot_item_clicked)
			if not slot.item_dropped.is_connected(_on_slot_item_dropped):
				slot.item_dropped.connect(_on_slot_item_dropped)
			if not slot.slot_swapped.is_connected(_on_slot_swapped):
				slot.slot_swapped.connect(_on_slot_swapped)
				
			# ---> NUOVI COLLEGAMENTI PER TRASCINAMENTO <---
			if not slot.drag_started.is_connected(_on_drag_started):
				slot.drag_started.connect(_on_drag_started)
			if not slot.drag_ended.is_connected(_on_drag_ended):
				slot.drag_ended.connect(_on_drag_ended)
		else:
			slot.add_item(null)

func _on_slot_item_clicked(item: InventoryItem):
	if inventory:
		inventory._on_slot_item_clicked(item)

func _on_slot_item_dropped(item: InventoryItem):
	if inventory:
		inventory.drop_item(item)
		
func _on_slot_swapped(source_slot, target_slot):
	if inventory:
		var slots = grid_container.get_children()
		for i in range(slots.size()):
			if i < inventory.items.size():
				inventory.items[i] = slots[i].current_item
		print("DEBUG: Memoria dello Zaino aggiornata!")

# ==========================================
# EFFETTO SCOMPARSA DURANTE IL TRASCINAMENTO
# ==========================================
func _on_drag_started():
	# Controlliamo se c'è una cassa aperta prima di sparire
	var chest_ui = get_tree().current_scene.get_node_or_null("ChestUI")
	if chest_ui and chest_ui.visible:
		hide() 

func _on_drag_ended():
	# Riappariamo solo se eravamo in modalità "scambio cassa"
	var chest_ui = get_tree().current_scene.get_node_or_null("ChestUI")
	if chest_ui and chest_ui.visible:
		show()
# ==========================================
# BOTTONE DI CHIUSURA ZAINO
# ==========================================
func _on_close_button_pressed():
	# Richiama il toggle per chiudere se stesso
	toggle()
