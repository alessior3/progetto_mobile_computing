extends CanvasLayer
class_name OnScreenUi

# AGGIUNTO: Segnale che avvisa l'inventario che un oggetto deve tornare nello zaino
signal request_unequip(item: InventoryItem)

@onready var hand: OnScreenEquipmentSlot = %hand
@onready var potions: OnScreenEquipmentSlot = %potions
@onready var food: OnScreenEquipmentSlot = %food
@onready var gold_label: Label=$GoldLabel

@onready var slots_dictionary = {
	"Hand": hand,
	"Potions": potions,
	"Food": food
}

func _ready() -> void:
	# Colleghiamo tutti gli slot (hand, potions, food) a questa UI
	for slot in slots_dictionary.values():
		if slot:
			# Ascoltiamo il segnale di ogni slot
			slot.unequip_requested.connect(_on_slot_unequip_requested)
	var inventory_node = get_parent().get_node_or_null("Inventory")
	if inventory_node:
		inventory_node.gold_changed.connect(_on_gold_changed)
		# Impostiamo il valore iniziale
		_on_gold_changed(inventory_node.gold)

func _on_gold_changed(new_amount: int):
	gold_label.text = "Oro: " + str(new_amount)

func _on_slot_unequip_requested(item: InventoryItem):
	# Inviamo la richiesta verso l'alto (all'Inventory)
	request_unequip.emit(item)

func equip_item(item: InventoryItem, slot_to_equip: String):
	if item == null:
		return
		
	if slots_dictionary.has(slot_to_equip):
		var slot_node = slots_dictionary[slot_to_equip]
		# MODIFICATA: Usiamo set_equipment_item (la nuova funzione dello slot)
		slot_node.set_equipment_item(item)
		print("DEBUG: Equipaggiato ", item.name, " nello slot ", slot_to_equip)
	else:
		print("ERRORE: Slot '", slot_to_equip, "' non trovato nel dizionario UI!")
