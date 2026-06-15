extends CanvasLayer
class_name OnScreenUi

signal request_unequip(item: InventoryItem)
signal eat_requested(item: InventoryItem)
signal request_drop(item: InventoryItem)

# RIFERIMENTI AI NODI
@onready var hand: OnScreenEquipmentSlot = %hand
@onready var potions: OnScreenEquipmentSlot = %potions
@onready var food: OnScreenEquipmentSlot = %food
@onready var gold_label: Label = %GoldLabel 

var slots_dictionary: Dictionary = {}

func _ready() -> void:
	_prepare_slots()
	
	# Connettiamo gli slot per l'unequip
	for slot in slots_dictionary.values():
		if slot:
			slot.unequip_requested.connect(_on_slot_unequip_requested)
			slot.eat_requested.connect(func(item): eat_requested.emit(item))
			slot.drop_requested.connect(_on_slot_drop_requested)
			
	# --- NOVITÀ: SINCRONIZZAZIONE INIZIALE ---
	# Appena la UI si sveglia, controlla cosa c'è salvato nel Global.
	# Se sei appena morto e il Global è vuoto (null), passerà "null" agli slot, svuotandoli visivamente!
	equip_item(Global.persistent_hand, "Hand")
	equip_item(Global.persistent_potions, "Potions")
	equip_item(Global.persistent_food, "Food")
	# -----------------------------------------
	
	# CERCHIAMO L'INVENTARIO: Ci colleghiamo al segnale dell'oro
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inv = player.get_node_or_null("Inventory")
		if inv:
			if not inv.gold_changed.is_connected(_on_gold_changed):
				inv.gold_changed.connect(_on_gold_changed)
			_on_gold_changed(Global.persistent_gold)
			
	# --- MIGLIORAMENTO GRAFICA ORO ---
	if gold_label:
		var custom_font = preload("res://Ninja Adventure - Asset Pack/Ui/Font/NormalFont.ttf")
		if custom_font:
			gold_label.add_theme_font_override("font", custom_font)
		
		# Impostazioni font
		gold_label.add_theme_font_size_override("font_size", 24)
		gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1)) # Colore dorato
		gold_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		gold_label.add_theme_constant_override("outline_size", 4)
		gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		gold_label.add_theme_constant_override("shadow_offset_x", 2)
		gold_label.add_theme_constant_override("shadow_offset_y", 2)
		
		gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Aggiunta box di sfondo (simile ai percorsi)
		var panel_texture = preload("res://Ninja Adventure - Asset Pack/Ui/Dialog/DialogueBoxSimple.png")
		var nine_patch = NinePatchRect.new()
		nine_patch.texture = panel_texture
		nine_patch.patch_margin_left = 12
		nine_patch.patch_margin_top = 12
		nine_patch.patch_margin_right = 12
		nine_patch.patch_margin_bottom = 12
		
		# Modifichiamo il colore del box (es: un marrone dorato scuro)
		nine_patch.modulate = Color(0.35, 0.2, 0.1, 0.95) 
		
		# Espande il box leggermente fuori dal testo per creare del margine
		nine_patch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		nine_patch.offset_left = -15
		nine_patch.offset_top = -10
		nine_patch.offset_right = 15
		nine_patch.offset_bottom = 10
		nine_patch.show_behind_parent = true
		
		gold_label.add_child(nine_patch)
	# ---------------------------------

func _prepare_slots():
	if slots_dictionary.is_empty():
		slots_dictionary = {
			"Hand": hand,
			"Potions": potions,
			"Food": food
		}

func _on_gold_changed(new_amount: int):
	if gold_label:
		gold_label.text = "Oro: " + str(new_amount)

func _on_slot_unequip_requested(item: InventoryItem):
	request_unequip.emit(item)

func _on_slot_drop_requested(item: InventoryItem):
	request_drop.emit(item)

func equip_item(item: InventoryItem, slot_to_equip: String):
	# Il fatto che tu abbia commentato la riga qui sotto è perfetto!
	# Permette alla UI di accettare "null" per cancellare l'icona.
	# if item == null: return
	
	_prepare_slots()
	if slots_dictionary.has(slot_to_equip):
		var slot_node = slots_dictionary[slot_to_equip]
		if slot_node:
			slot_node.set_equipment_item(item)
