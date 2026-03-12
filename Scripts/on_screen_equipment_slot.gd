extends VBoxContainer
class_name OnScreenEquipmentSlot

signal unequip_requested(item: InventoryItem)
signal eat_requested(item: InventoryItem) # NUOVO SEGNALE per il cibo

@onready var texture_rect: TextureRect = %TextureRect
@onready var menu_button: MenuButton = %MenuButton 
@onready var slot_label: Label = $slotLabel

@export var slot_name: String
var current_item: InventoryItem = null

func _ready() -> void:
	slot_label.text = slot_name
	var popup = menu_button.get_popup()
	popup.id_pressed.connect(_on_popup_item_pressed)

func set_equipment_item(item: InventoryItem):
	current_item = item
	var popup = menu_button.get_popup()
	
	# Puliamo il menu ogni volta, così lo ricostruiamo su misura
	popup.clear() 

	if item:
		texture_rect.texture = item.texture
		menu_button.disabled = false 
		
		# 1. Aggiungiamo sempre l'opzione di base (ID = 0)
		popup.add_item("Unequip", 0)
		
		# 2. Se l'oggetto ha la spunta "is_consumable", aggiungiamo "Eat" (ID = 1)
		if item.get("is_consumable") == true:
			popup.add_item("Eat", 1)
			
	else:
		texture_rect.texture = null
		menu_button.disabled = true 

func _on_popup_item_pressed(id: int):
	if not current_item: return
	
	if id == 0:
		print("DEBUG (Slot): Menu 'Unequip' premuto per ", current_item.name)
		unequip_requested.emit(current_item)
		set_equipment_item(null) # Lo svuotiamo visivamente
		
	elif id == 1:
		print("DEBUG (Slot): Menu 'Eat' premuto per ", current_item.name)
		eat_requested.emit(current_item)
		# NOTA: Non svuotiamo lo slot qui! Lo farà il Player controllando 
		# se sono finiti gli stack (i ravanelli) dopo aver mangiato.
