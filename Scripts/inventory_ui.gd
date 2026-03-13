extends CanvasLayer
class_name InventoryUI

@onready var grid_container: GridContainer = %GridContainer
@onready var details_label: Label = %DetailsLabel 
@onready var equip_button: Button = %EquipButton # Nuovo bottone
@onready var drop_button: Button = %DropButton   # Nuovo bottone
@onready var main_panel = $MarginContainer 
@onready var item_icon: TextureRect = %ItemIcon
@onready var item_name_label = %ItemNameLabel

const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")
@export var inventory: Inventory 
@export var size: int = 20 
@export var columns: int = 5 

var posizione_centrale_y: float = 0.0
var selected_item: InventoryItem = null # Il "cervello" che ricorda l'oggetto selezionato!
var current_active_slot: InventorySlot = null

func _ready() -> void:    
	await get_tree().process_frame
	print("INVENTARIO REALE - Size: ", $MarginContainer/NinePatchRect.size)
	grid_container.columns = columns
	for i in size:
		var inventory_slot = INVENTORY_SLOT_SCENE.instantiate()
		grid_container.add_child(inventory_slot)
		
	# Colleghiamo i nuovi bottoni fisici!
	equip_button.pressed.connect(_on_equip_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	_nascondi_bottoni()
	
	hide()
	await get_tree().process_frame
	if main_panel:
		posizione_centrale_y = main_panel.position.y

func toggle():
	visible = !visible
	if visible and inventory:
		# Resetta l'interfaccia quando la apri
		if details_label:
			details_label.text = "Seleziona un oggetto"
		selected_item = null
		_nascondi_bottoni()
		
		update_slots(inventory.items)
		if main_panel:
			main_panel.position.y = posizione_centrale_y
		
		if not visible and current_active_slot:
			current_active_slot.set_highlight(false)
			current_active_slot = null

func update_slots(items_list: Array[InventoryItem]):
	var slots = grid_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		if i < items_list.size():
			slot.add_item(items_list[i])
			
			if not slot.slot_swapped.is_connected(_on_slot_swapped):
				slot.slot_swapped.connect(_on_slot_swapped)
			if not slot.drag_started.is_connected(_on_drag_started):
				slot.drag_started.connect(_on_drag_started)
			if not slot.drag_ended.is_connected(_on_drag_ended):
				slot.drag_ended.connect(_on_drag_ended)
			if not slot.slot_focused.is_connected(_on_slot_focused):
				slot.slot_focused.connect(_on_slot_focused)
		else:
			slot.add_item(null)

# ==========================================
# LOGICA DEI BOTTONI
# ==========================================
func _on_slot_focused(slot: InventorySlot):
	# 1. Gestione highlight (come prima)
	if current_active_slot != null:
		current_active_slot.set_highlight(false)
	
	current_active_slot = slot
	current_active_slot.set_highlight(true)
	
	# 2. Gestione dettagli
	var item = slot.current_item
	selected_item = item 
	
	if item:
		item_icon.texture = item.texture
		item_icon.show()
		
		# 1. Mettiamo il nome nella Label grande
		if item_name_label:
			item_name_label.text = item.name
			
		# 2. Mettiamo la descrizione nella Label piccola
		if details_label:
			var desc = item.get("description")
			if desc == null or desc == "":
				desc = "Nessuna descrizione disponibile."
			details_label.text = desc
			
		_mostra_bottoni()

func _on_equip_pressed():
	if selected_item != null and inventory:
		inventory._on_slot_item_clicked(selected_item)

func _on_drop_pressed():
	if selected_item != null and inventory:
		inventory.drop_item(selected_item)
		# Dopo aver buttato l'oggetto, puliamo lo schermo
		selected_item = null
		details_label.text = "Oggetto lasciato cadere."
		_nascondi_bottoni()
	if current_active_slot:
		current_active_slot.set_highlight(false)
		current_active_slot = null

func _nascondi_bottoni():
	if equip_button and drop_button:
		equip_button.hide()
		drop_button.hide()

func _mostra_bottoni():
	if equip_button and drop_button:
		equip_button.show()
		drop_button.show()

# ==========================================
# GESTIONE ZAINO
# ==========================================
func _on_slot_swapped(source_slot, target_slot):
	if inventory:
		var slots = grid_container.get_children()
		for i in range(slots.size()):
			if i < inventory.items.size():
				inventory.items[i] = slots[i].current_item

func _on_drag_started():
	var chest_ui = get_tree().current_scene.get_node_or_null("ChestUI")
	if chest_ui and chest_ui.visible: hide() 

func _on_drag_ended():
	var chest_ui = get_tree().current_scene.get_node_or_null("ChestUI")
	if chest_ui and chest_ui.visible: show()

func _on_close_button_pressed():
	toggle()
