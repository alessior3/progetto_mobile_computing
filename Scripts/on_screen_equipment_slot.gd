extends VBoxContainer
class_name OnScreenEquipmentSlot

signal unequip_requested(item: InventoryItem)

@onready var texture_rect: TextureRect = %TextureRect
@onready var menu_button: MenuButton = %MenuButton # Riferimento al nuovo MenuButton
@onready var slot_label: Label = $slotLabel

@export var slot_name: String
var current_item: InventoryItem = null

func _ready() -> void:
	slot_label.text = slot_name
	# Colleghiamo il segnale del menu a tendina
	var popup = menu_button.get_popup()
	popup.id_pressed.connect(_on_popup_item_pressed)

func set_equipment_item(item: InventoryItem):
	current_item = item
	if item:
		texture_rect.texture = item.texture
		menu_button.disabled = false # Riabilitiamo il menu se c'è un oggetto
	else:
		texture_rect.texture = null
		menu_button.disabled = true # Disabilitiamo il menu se lo slot è vuoto

func _on_popup_item_pressed(id: int):
	# Se l'ID è 0 (ovvero "Unequip"), lanciamo il segnale per l'inventario
	if id == 0 and current_item:
		print("DEBUG (Slot): Menu 'Unequip' premuto per ", current_item.name)
		unequip_requested.emit(current_item)
		set_equipment_item(null)
