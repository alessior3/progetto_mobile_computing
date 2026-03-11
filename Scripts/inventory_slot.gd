extends VBoxContainer
class_name InventorySlot

var is_empty = true
var is_selected = false
var current_item: InventoryItem = null

# SEGNALI
signal slot_clicked(item: InventoryItem) 
signal item_dropped(item: InventoryItem) # Nuovo segnale per il drop
signal slot_swapped(source_slot, target_slot)
@export var single_button_press = false
@export var starting_texture: Texture
@export var start_label: String

# Usiamo % per trovare i nodi indipendentemente dalla gerarchia
@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %nameLabel
@onready var stacks_label: Label = %stacksLabel
@onready var on_click_button: Button = %onClickButton
@onready var menu_button: MenuButton = %MenuButton
@onready var price_label: Label = %priceLabel

func _ready() -> void:
	if on_click_button:
		on_click_button.pressed.connect(_on_equip_button_pressed)
	
	if starting_texture: texture_rect.texture = starting_texture
	if start_label: name_label.text = start_label
	
	menu_button.disabled = single_button_press
	on_click_button.disabled = !single_button_press
	on_click_button.visible = single_button_press
	
	var popup_menu = menu_button.get_popup()
	popup_menu.id_pressed.connect(on_popup_menu_item_pressed)

func add_item(item: InventoryItem):
	current_item = item
	if item:
		texture_rect.texture = item.texture
		name_label.text = item.name
		if stacks_label: 
			stacks_label.text = str(item.stacks) if item.stacks > 1 else ""
		is_empty = false
	else:
		texture_rect.texture = null
		name_label.text = ""
		is_empty = true    

func show_price_tag(price: int):
	if price_label:
		# Usiamo \n per mandare a capo se vuoi il prezzo sotto il nome
		# O semplicemente puliamo la stringa
		price_label.text = str(price) + " Gold"
		price_label.visible = true
		
		# Invece di modulate, usiamo LabelSettings per renderlo "Premium"
		if not price_label.label_settings:
			var settings = LabelSettings.new()
			settings.font_color = Color.GOLD
			settings.outline_size = 4
			settings.outline_color = Color.BLACK # Il contorno lo rende leggibile ovunque
			settings.font_size = 12 # Regola la dimensione come preferisci
			price_label.label_settings = settings
			
func toggle_button_selected_variation(selected: bool):
	is_selected = selected
	if selected:
		modulate = Color(1.5, 1.5, 1.5)
	else:
		modulate = Color.WHITE

func _on_equip_button_pressed():
	if current_item and !is_empty:
		slot_clicked.emit(current_item)

func on_popup_menu_item_pressed(id: int):
	if current_item and !is_empty:
		if id == 0:
			slot_clicked.emit(current_item) # Equipaggia
		elif id == 1:
			item_dropped.emit(current_item) # Droppa
# ==========================================
# SISTEMA DI TRASCINAMENTO (DRAG & DROP)
# ==========================================

func _get_drag_data(at_position: Vector2) -> Variant:
	# Se lo slot è vuoto, non c'è nulla da trascinare
	if is_empty or current_item == null:
		return null

	# 1. Creiamo un "pacchetto" con i dati da inviare
	var data = {
		"source_slot": self,
		"item": current_item
	}

	# 2. Creiamo il "fantasma" visivo che segue il mouse
	var preview_texture = TextureRect.new()
	preview_texture.texture = current_item.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(40, 40) # Dimensione dell'icona volante
	preview_texture.modulate = Color(1, 1, 1, 0.7) # La facciamo mezza trasparente

	var preview_control = Control.new()
	preview_control.add_child(preview_texture)
	preview_texture.position = -preview_texture.custom_minimum_size / 2
	set_drag_preview(preview_control)

	return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Accetta il rilascio solo se i dati contengono l'oggetto e lo slot di origine
	return typeof(data) == TYPE_DICTIONARY and data.has("item") and data.has("source_slot")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var source_slot = data["source_slot"]
	
	# Se rilascio l'oggetto nello stesso identico quadratino da cui l'ho preso, non fare nulla
	if source_slot == self:
		return 

	# 3. SCAMBIO DEGLI OGGETTI (La magia di Minecraft!)
	var my_old_item = current_item
	var dragged_item = data["item"]

	# Lo slot di origine prende il mio oggetto (anche se è vuoto)
	source_slot.add_item(my_old_item)
	# Io (slot di destinazione) prendo l'oggetto trascinato
	self.add_item(dragged_item)

	# 4. Suoniamo l'allarme che i due slot si sono scambiati i posti
	source_slot.slot_swapped.emit(source_slot, self)
	self.slot_swapped.emit(source_slot, self)
