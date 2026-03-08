extends VBoxContainer

class_name InventorySlot

var is_empty=true
var is_selected=false

signal item_clicked(item: InventoryItem) # Nuovo segnale

var current_item: InventoryItem = null # Per ricordarsi l'oggetto

@export var single_button_press=false
@export var starting_texture: Texture
@export var start_label: String

@onready var texture_rect: TextureRect=$NinePatchRect/MenuButton/CenterContainer/TextureRect
@onready var name_label: Label=$NinePatchRect/nameLabel
@onready var stacks_label:Label=$NinePatchRect/stacksLabel
@onready var on_click_button:Button=$NinePatchRect/onClickButton
@onready var menu_button:MenuButton=$NinePatchRect/MenuButton

var slot_to_equip="NotEquipable"

func _ready() -> void:
	# Colleghiamo il tuo bottone on_click_button alla funzione di invio
	on_click_button.pressed.connect(_on_equip_button_pressed)
	if starting_texture!=null:
		texture_rect.texture=starting_texture
	
	if start_label!=null:
		name_label.text=start_label
	
	menu_button.disabled=single_button_press
	on_click_button.disabled=!single_button_press
	
	on_click_button.visible=single_button_press
	
	var popup_menu=menu_button.get_popup()
	popup_menu.id_pressed.connect(on_popup_menu_item_pressed)
	
func on_popup_menu_item_pressed(id: int):
	# Supponiamo che l'ID 0 sia "Equip"
	if id == 0: 
		if current_item != null and !is_empty:
			print("DEBUG (Slot): Equipaggiamento richiesto per ", current_item.name)
			item_clicked.emit(current_item) # Invia l'oggetto all'inventario
	elif id == 1:
		print("DEBUG (Slot): Opzione Drop selezionata (da implementare)")
	
func _on_equip_button_pressed():
	if current_item and !is_empty:
		item_clicked.emit(current_item) # Invia l'oggetto a chi ascolta
		print("DEBUG (Slot): Invio segnale equip per: ", current_item.name)

func display_item(item: InventoryItem):
	current_item = item # Salva l'oggetto corrente
	if item:
		texture_rect.texture = item.texture
		name_label.text = item.name
		is_empty = false #
	else:
		texture_rect.texture = null
		name_label.text = ""
		is_empty = true #
