extends VBoxContainer
class_name InventorySlot

var is_empty = true
var is_selected = false
var current_item: InventoryItem = null

# Unico segnale necessario per i click!
signal slot_focused(slot: InventorySlot)
signal slot_swapped(source_slot, target_slot)
signal drag_started 
signal drag_ended   

@export var starting_texture: Texture

@onready var texture_rect: TextureRect = %TextureRect
@onready var stacks_label: Label = %stacksLabel
@onready var slot_button: Button = %SlotButton # Il nuovo bottone semplice!
@onready var selection_highlight = %SelectionHighlight

func _ready() -> void:
	if starting_texture: texture_rect.texture = starting_texture
	slot_button.pressed.connect(_on_slot_button_pressed)

func add_item(item: InventoryItem):
	current_item = item
	if item:
		texture_rect.texture = item.texture
		if stacks_label:
			stacks_label.text = str(item.stacks) if item.stacks > 1 else ""
		is_empty = false
	else:
		texture_rect.texture = null
		if stacks_label:
			stacks_label.text = ""
		is_empty = true

func _on_slot_button_pressed():
	# Mandiamo "self" così l'UI sa esattamente quale slot spegnere/accendere
	if not is_empty and current_item:
		slot_focused.emit(self)

# ==========================================
# TRASCINAMENTO (Invariato)
# ==========================================
func _get_drag_data(at_position: Vector2) -> Variant:
	if is_empty or current_item == null: return null
	var data = {"source_slot": self, "item": current_item}
	var preview_texture = TextureRect.new()
	preview_texture.texture = current_item.texture
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.custom_minimum_size = Vector2(40, 40)
	preview_texture.modulate = Color(1, 1, 1, 0.7) 
	var preview_control = Control.new()
	preview_control.add_child(preview_texture)
	preview_texture.position = -preview_texture.custom_minimum_size / 2
	set_drag_preview(preview_control)
	drag_started.emit()
	return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("item") and data.has("source_slot")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var source_slot = data["source_slot"]
	if source_slot == self: return 
	var my_old_item = current_item
	var dragged_item = data["item"]
	source_slot.add_item(my_old_item)
	self.add_item(dragged_item)
	source_slot.slot_swapped.emit(source_slot, self)
	self.slot_swapped.emit(source_slot, self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()

func set_highlight(active: bool):
	if selection_highlight:
		selection_highlight.visible = active
		
