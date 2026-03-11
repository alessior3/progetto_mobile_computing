extends CanvasLayer

@onready var grid = $Background/Grid

# Il percorso del tuo slot (lasciato intatto)
var slot_scene = preload("res://Scenes/UI/inventory_slot.tscn")

# Variabili di memoria
var current_chest_id: String = ""
var linked_chest: Area2D = null # La cassa fisica che stiamo usando

func _ready():
	hide() 

# MODIFICATO: Ora riceve anche la "physical_chest" (la cassa fisica)
func open_chest_ui(chest_items: Array, chest_id: String, physical_chest: Area2D):
	show()
	current_chest_id = chest_id
	linked_chest = physical_chest
	
	# 1. Puliamo la griglia da vecchi slot
	for child in grid.get_children():
		child.queue_free()
		
	# 2. Creiamo un quadratino per ogni spazio disponibile
	for item in chest_items:
		var new_slot = slot_scene.instantiate()
		grid.add_child(new_slot)
		new_slot.add_item(item)
		
		if not new_slot.slot_swapped.is_connected(_on_chest_slot_swapped):
			new_slot.slot_swapped.connect(_on_chest_slot_swapped)

func close_chest_ui():
	hide()
	current_chest_id = "" 
	linked_chest = null # Pulizia memoria

# Salva i dati quando sposti qualcosa
func _on_chest_slot_swapped(source_slot, target_slot):
	var updated_items: Array = []
	var slots = grid.get_children()
	
	for slot in slots:
		updated_items.append(slot.current_item)
		
	if current_chest_id != "":
		Global.chests_data[current_chest_id] = updated_items
		print("DEBUG: Memoria della Cassa (", current_chest_id, ") salvata con successo!")

# NUOVA FUNZIONE: Verrà chiamata dal bottone per chiudere tutto
func _on_close_button_pressed():
	if linked_chest:
		# Diciamo alla cassa fisica di avviare la chiusura (che chiuderà anche lo zaino)
		linked_chest.toggle_chest()
