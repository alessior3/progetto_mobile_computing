extends VBoxContainer

class_name InventorySlot

var is_empty=true
var is_selected=false

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
	print_debug(id)
	
func display_item(item: InventoryItem):
	if item:
		# Mostra l'icona e il nome dell'oggetto
		texture_rect.texture = item.texture
		name_label.text = item.name
		is_empty = false
	else:
		# Se lo slot deve essere vuoto, pulisci tutto
		texture_rect.texture = null
		name_label.text = ""
		is_empty = true
