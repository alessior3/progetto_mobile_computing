extends CanvasLayer

@onready var grid = $ChestContainer/MainBody/Grid

# Il percorso della scena del tuo quadratino dell'inventario
var slot_scene = preload("res://Scenes/UI/inventory_slot.tscn")

var current_chest_id: String = ""
var linked_chest: Area2D = null

# NUOVO: Ricorda se abbiamo forzato l'apertura dello zaino col trascinamento
var auto_opened_inventory: bool = false

func _ready():
	hide() 
	
	# COLLEGAMENTO FORZATO DEL BOTTONE INVENTARIO VIA CODICE
	var inv_btn = get_node_or_null("FakeInventoryButton")
	if inv_btn != null:
		if not inv_btn.pressed.is_connected(_on_inventory_button_pressed):
			inv_btn.pressed.connect(_on_inventory_button_pressed)
			print("DEBUG: Cavo del FakeInventoryButton collegato con successo all'avvio!")
	else:
		print("ERRORE: Non trovo il nodo FakeInventoryButton! Assicurati che non sia dentro altri nodi.")

func open_chest_ui(chest_items: Array, chest_id: String, physical_chest: Area2D):
	show()
	current_chest_id = chest_id
	linked_chest = physical_chest
	
	for child in grid.get_children():
		child.queue_free()
		
	for i in range(chest_items.size()):
		var item = chest_items[i]
		
		# Evita i crash se per sbaglio è stato inserito un AtlasTexture (o altro) invece di un InventoryItem
		if item != null and not item is InventoryItem:
			print("ERRORE CASSA (", chest_id, "): L'oggetto inserito non è un InventoryItem valido! Verrà rimosso.")
			item = null
			chest_items[i] = null
			
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
		
		# NUOVO: Click per prelevare!
		if not new_slot.slot_focused.is_connected(_on_chest_slot_focused):
			new_slot.slot_focused.connect(_on_chest_slot_focused)

func _on_chest_slot_focused(slot: InventorySlot):
	if linked_chest and linked_chest.current_player:
		var inv = linked_chest.current_player.get_node_or_null("Inventory")
		if inv and slot.current_item != null:
			var item = slot.current_item
			
			var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
			if not inv_ui: inv_ui = linked_chest.current_player.get_node_or_null("InventoryUI")
			
			if inv_ui:
				var added = false
				for i in range(inv.items.size()):
					if inv.items[i] == null:
						inv.items[i] = item
						added = true
						break
				if not added and inv.items.size() < inv_ui.size:
					inv.items.append(item)
					added = true
					
				if added:
					Global.persistent_items = inv.items
					slot.add_item(null)
					_on_chest_slot_swapped(slot, slot)
					inv_ui.update_slots(inv.items)
			else:
				print("Zaino pieno, impossibile raccogliere dalla cassa!")

func close_chest_ui():
	# Chiudiamo lo zaino in automatico se stiamo chiudendo la cassa ed era rimasto aperto
	if linked_chest and linked_chest.current_player:
		# Controllo di sicurezza: cerchiamo l'inventario sia con la minuscola che con la maiuscola
		var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
		if inv_ui == null: 
			inv_ui = linked_chest.current_player.get_node_or_null("InventoryUI")
			
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
		# Aggiorna il salvataggio globale
		Global.chests_data[current_chest_id] = updated_items
		
		# --- LA MODIFICA CHIAVE: Aggiorna la cassa fisica! ---
		if linked_chest:
			linked_chest.chest_items = updated_items
		# -----------------------------------------------------
		
		print("DEBUG: Memoria della Cassa (", current_chest_id, ") salvata con successo!")

# Bottone X della Cassa
func _on_close_button_pressed():
	if linked_chest:
		linked_chest.toggle_chest()

# ==========================================
# Bottone Zaino (Premuto manualmente)
# ==========================================
func _on_inventory_button_pressed():
	print("DEBUG: Tasto Inventario premuto dalla cassa!")
	
	if linked_chest != null:
		if linked_chest.current_player != null:
			# Cerchiamo l'inventario (proviamo sia con la minuscola che con la maiuscola)
			var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
			if inv_ui == null:
				inv_ui = linked_chest.current_player.get_node_or_null("InventoryUI")
				
			if inv_ui != null:
				print("DEBUG: Interfaccia Zaino trovata! La apro/chiudo ora.")
				inv_ui.toggle()
			else:
				print("ERRORE: Non riesco a trovare il nodo 'inventoryUI' (o 'InventoryUI') dentro al Player!")
		else:
			print("ERRORE: La cassa non sa chi è il Player (current_player è null)!")
	else:
		print("ERRORE: La cassa non è collegata (linked_chest è null)!")

# ==========================================
# MAGIA INVERSA: COMPARSA DELLO ZAINO COL TRASCINAMENTO
# ==========================================
func _on_chest_drag_started():
	if linked_chest and linked_chest.current_player:
		var inv_ui = linked_chest.current_player.get_node_or_null("inventoryUI")
		if inv_ui == null:
			inv_ui = linked_chest.current_player.get_node_or_null("InventoryUI")
		
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
		if inv_ui == null:
			inv_ui = linked_chest.current_player.get_node_or_null("InventoryUI")
		
		# Quando stacchi il dito, lo richiudiamo SOLO se eravamo stati noi ad aprirlo in automatico
		if auto_opened_inventory and inv_ui and inv_ui.visible:
			inv_ui.visible = false
			auto_opened_inventory = false
