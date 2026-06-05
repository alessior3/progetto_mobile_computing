extends Area2D

class_name BinarySocket

signal power_changed(value: int)

@export var bit_value: int = 1 # 1, 2, 4, 8
@export var is_high_signal: bool = false
@export var is_locked: bool = false
@export var gold_cost: int = 10 # Dilemma morale: costa oro attivare i bit!
@export var current_item: InventoryItem = null

const GOLD_COIN = preload("res://Resources/GoldCoin/gold_coin.tres")

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
		if is_locked:
			print("DEBUG: Socket bloccato. Le monete sono fuse col metallo!")
			return
			
		print("DEBUG: Tasto Interact premuto nel raggio del Socket ", bit_value)
		if current_item == null:
			_try_insert_item()
		else:
			_try_extract_item()

func _try_insert_item():
	if player_ref:
		var inv = player_ref.get_node_or_null("Inventory")
		if inv and inv.has_gold(gold_cost):
			inv.remove_gold(gold_cost)
			print("DEBUG: Pagato ", gold_cost, " oro per il socket ", bit_value)
			
			current_item = GOLD_COIN
			is_high_signal = true
			_update_visuals()
			power_changed.emit(bit_value)
			print("DEBUG: Inserito ORO nel socket ", bit_value, ". Segnale: ALTO")
		else:
			print("DEBUG: Non hai abbastanza oro per attivare il socket!")

func _try_extract_item():
	if player_ref:
		if current_item != null:
			# C'è già una moneta, il giocatore la ritira
			var inv = player_ref.get_node_or_null("Inventory")
			if inv and inv.has_method("smart_add_pickup"):
				# Adesso passiamo 1 come quantità di oggetti, perché una singola moneta vale già 10 ori
				inv.smart_add_pickup(current_item, 1)
				print("DEBUG: Restituita 1 moneta (valore: ", gold_cost, " ori) all'inventario.")
	
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
			sprite_item.texture = preload("res://Ninja Adventure - Asset Pack/Items/Treasure/GoldCoin.png")
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
