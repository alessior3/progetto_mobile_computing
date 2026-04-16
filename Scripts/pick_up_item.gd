@tool
extends Area2D
class_name PickUpItem

# ID Univoco: fondamentale impostarlo nell'Inspector per ogni oggetto!
@export var item_id: String = ""

@export var inventory_item : InventoryItem :
	set(value):
		inventory_item = value
		_update_visuals()

@export var amount: int = 1

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var player_in_range : bool = false
var current_player : CharacterBody2D = null

func _ready() -> void:
	# 1. CONTROLLO PERSISTENZA (Solo in gioco)
	if not Engine.is_editor_hint():
		# Se l'ID è già stato raccolto, l'oggetto si auto-elimina subito
		if item_id != "" and Global.collected_item_ids.has(item_id):
			queue_free()
			return 
		
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	
	_update_visuals()

# In PickUpItem.gd

func _update_visuals() -> void:
	if not is_inside_tree(): return
	
	var s2d = sprite_2d if sprite_2d else get_node_or_null("Sprite2D")
	
	if inventory_item:
		if s2d: 
			s2d.texture = inventory_item.texture
		# --- APPLICHIAMO LA SCALA DELLA RISORSA ---
		self.scale = inventory_item.ground_visual_scale
	else:
		if s2d: s2d.texture = null

# --- LOGICA DI GIOCO ---

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return 
	
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").stop()
		current_player = null

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	
	if player_in_range and event.is_action_pressed("interact"):
		collect()

func collect() -> void:
	if current_player and inventory_item:
		var player_inv = current_player.get_node_or_null("Inventory")
		if player_inv:
			# --- LA MODIFICA È QUI: Usiamo smart_add_pickup invece di add_item ---
			if player_inv.has_method("smart_add_pickup"):
				player_inv.smart_add_pickup(inventory_item, amount)
			else:
				player_inv.add_item(inventory_item, amount) # Fallback di sicurezza
			# ----------------------------------------------------------------------
			
			# Registriamo l'ID nella lista globale prima di sparire
			if item_id != "":
				Global.collected_item_ids.append(item_id)
				print("DEBUG (PickUp): Registrata raccolta ID: ", item_id)
			
			print("DEBUG (PickUp): Raccolti ", amount, "x ", inventory_item.name)
		else:
			print("ERRORE: Inventario non trovato sul Player!")
	
	queue_free()
