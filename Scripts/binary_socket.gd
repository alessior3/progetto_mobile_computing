extends Area2D

class_name BinarySocket

signal power_changed(value: int)

@export var bit_value: int = 1 # 1, 2, 4, 8
@export var is_high_signal: bool = false
@export var current_item: InventoryItem = null

@onready var sprite_item = $SpriteItem
@onready var sprite_socket = $SpriteSocket
@onready var light_feedback = $PointLight2D

var player_in_range = false
var player_ref = null

func _ready():
	monitoring = true # Forza l'ascolto delle collisioni
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()

func _on_body_entered(body):
	print("DEBUG: Qualcosa è entrato nell'area del socket: ", body.name)
	if body.is_in_group("player") or body.name == "player":
		player_in_range = true
		player_ref = body
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play_backwards("KeyPrompt")
		player_ref = null

func _input(event):
	if player_in_range and event.is_action_pressed("interact"):
		print("DEBUG: Tasto Interact premuto nel raggio del Socket ", bit_value)
		if current_item == null:
			_try_insert_item()
		else:
			_try_extract_item()

func _try_insert_item():
	if player_ref and Global.persistent_food:
		var item = Global.persistent_food
		print("DEBUG: Tentativo inserimento. Item attivo: ", item.name)
		current_item = item
		is_high_signal = _is_item_high_signal(item)
		if player_ref.has_method("consume_food_item"):
			player_ref.consume_food_item(item)
		_update_visuals()
		power_changed.emit(bit_value if is_high_signal else 0)
		print("DEBUG: Inserito ", item.name, " nel socket ", bit_value, ". Segnale: ", "ALTO" if is_high_signal else "BASSO")

func _try_extract_item():
	if player_ref and current_item:
		var inv = player_ref.get_node_or_null("Inventory")
		if inv and inv.has_method("smart_add_pickup"):
			current_item.stacks = 1
			inv.smart_add_pickup(current_item, 1)
			print("DEBUG: Restituito ", current_item.name, " all'inventario.")
	
	current_item = null
	is_high_signal = false
	_update_visuals()
	power_changed.emit(0)
	print("DEBUG: Socket ", bit_value, " svuotato.")

func _is_item_high_signal(item: InventoryItem) -> bool:
	var item_name_lower = item.name.to_lower()
	var high_keywords = ["barbabietola", "slime", "wing", "phantom", "spider", "drop"]
	
	for key in high_keywords:
		if key in item_name_lower:
			return true
	return false

func _update_visuals():
	if sprite_item:
		if current_item:
			sprite_item.texture = current_item.texture
			sprite_item.show()
		else:
			sprite_item.hide()
	
	if light_feedback:
		light_feedback.enabled = (current_item != null)
		light_feedback.energy = 2.0
		light_feedback.texture_scale = 1.5
		
		if is_high_signal:
			light_feedback.color = Color(0, 1, 1) # Cyan per segnale ALTO
		else:
			light_feedback.color = Color(1, 0.4, 0) # Arancione per segnale BASSO
