extends CanvasLayer

@onready var grid = $Background/Grid

# Il percorso della scena del tuo quadratino dell'inventario
var slot_scene = preload("res://Scenes/UI/inventory_slot.tscn")

var current_chest_id: String = ""
var linked_chest: Area2D = null

# NUOVO: Ricorda se abbiamo forzato l'apertura dello zaino col trascinamento
var auto_opened_inventory: bool = false

func _ready():
	hide() 

func open_chest_ui(chest_items: Array, chest_id: String, physical_chest: Area2D):
	show()
	current_chest_id = chest_id
	linked_chest = physical_chest
	
	for child in grid.get_children():
		child.queue_free()
		
	for item in chest_items:
		var new_slot = slot_scene.instantiate()
		grid.add_child(new_slot)
		new_slot.add_item(item)
		
		# Connessione per il salvataggio
		if not new_slot.slot_swapped.is_connected(_on_chest_slot_swapped):
			new_slot.slot_swapped.connect(_on_chest_slot_swapped)
			
		# NUOVI COLLEGAMENTI: Ascoltiamo il trascinamento dalla Cassa!
		if not new_slot.drag_started.is_connected(_on_chest_drag_started):
			new_slot.drag_started.connect(_on_chest_drag_started)
		if not new_slot.drag_ended.is_connected(_on_chest_drag_ended):
			new_slot.drag_ended.connect(_on_chest_drag_ended)

func close_chest_ui():
	# Chiudiamo lo zaino in automatico se stiamo chiudendo la cassa ed era rimasto aperto
	if linked_chest and linked_chest.current_player:
		var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
		if inv_ui and inv_ui.visible:
			inv_ui.toggle()
			
	hide()
	current_chest_id = ""
	linked_chest = null

# Salva i dati quando sposti qualcosa
func _on_chest_slot_swapped(source_slot, target_slot):
	var updated_items: Array = []
	var slots = grid.get_children()
	
	for slot in slots:
		updated_items.append(slot.current_item)
		
	if current_chest_id != "":
		Global.chests_data[current_chest_id] = updated_items
		print("DEBUG: Memoria della Cassa (", current_chest_id, ") salvata con successo!")

# Bottone X della Cassa
func _on_close_button_pressed():
	if linked_chest:
		linked_chest.toggle_chest()

# Bottone Zaino (se lo usi da dentro la cassa per aprirlo manualmente)
func _on_inventory_button_pressed():
	if linked_chest and linked_chest.current_player:
		var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
		if inv_ui:
			inv_ui.toggle()

# ==========================================
# MAGIA INVERSA: COMPARSA DELLO ZAINO
# ==========================================
func _on_chest_drag_started():
	if linked_chest and linked_chest.current_player:
		var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
		
		# Se lo zaino è chiuso, lo facciamo apparire noi per farti mirare
		if inv_ui and not inv_ui.visible:
			auto_opened_inventory = true
			inv_ui.visible = true
			if inv_ui.inventory:
				inv_ui.update_slots(inv_ui.inventory.items)
		else:
			# Se era già aperto perché avevi premuto tu il tasto, non facciamo nulla di speciale
			auto_opened_inventory = false

func _on_chest_drag_ended():
	if linked_chest and linked_chest.current_player:
		var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
		
		# Quando stacchi il dito, lo richiudiamo SOLO se eravamo stati noi ad aprirlo in automatico
		if auto_opened_inventory and inv_ui and inv_ui.visible:
			inv_ui.visible = false
			auto_opened_inventory = false
