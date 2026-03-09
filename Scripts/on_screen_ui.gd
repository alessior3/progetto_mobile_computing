extends CanvasLayer
class_name OnScreenUi

signal request_unequip(item: InventoryItem)

# RIFERIMENTI AI NODI
@onready var hand: OnScreenEquipmentSlot = %hand
@onready var potions: OnScreenEquipmentSlot = %potions
@onready var food: OnScreenEquipmentSlot = %food
@onready var gold_label: Label = %GoldLabel # Assicurati che l'Unique Name sia attivo!

var slots_dictionary: Dictionary = {}

func _ready() -> void:
	_prepare_slots()
	
	# Connettiamo gli slot per l'unequip
	for slot in slots_dictionary.values():
		if slot:
			slot.unequip_requested.connect(_on_slot_unequip_requested)
	
	# CERCHIAMO L'INVENTARIO: Ci colleghiamo al segnale dell'oro
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inv = player.get_node_or_null("Inventory")
		if inv:
			# Se il segnale non è connesso, lo connettiamo
			if not inv.gold_changed.is_connected(_on_gold_changed):
				inv.gold_changed.connect(_on_gold_changed)
			# Forziamo l'aggiornamento iniziale con i dati del Global
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
		gold_label.text = "Oro: " + str(new_amount) # Ecco che riappare la scritta!

func _on_slot_unequip_requested(item: InventoryItem):
	request_unequip.emit(item)

func equip_item(item: InventoryItem, slot_to_equip: String):
	if item == null: return
	_prepare_slots()
	if slots_dictionary.has(slot_to_equip):
		var slot_node = slots_dictionary[slot_to_equip]
		if slot_node:
			slot_node.set_equipment_item(item)
