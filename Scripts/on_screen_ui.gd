extends CanvasLayer
class_name OnScreenUi

signal request_unequip(item: InventoryItem)
signal eat_requested(item: InventoryItem)

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

func equip_item(item: InventoryItem, slot_to_equip: String):
	# Il fatto che tu abbia commentato la riga qui sotto è perfetto!
	# Permette alla UI di accettare "null" per cancellare l'icona.
	# if item == null: return
	
	_prepare_slots()
	if slots_dictionary.has(slot_to_equip):
		var slot_node = slots_dictionary[slot_to_equip]
		if slot_node:
			slot_node.set_equipment_item(item)
