extends Area2D

class_name PickUpItem

@export var inventory_item : InventoryItem

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var player_in_range : bool = false
var current_player : CharacterBody2D = null # Memorizziamo chi è entrato

func _ready() -> void:
	# Sicurezza: se dimentichi di mettere lo stick.tres, non crasha il gioco
	if inventory_item == null:
		print("ATTENZIONE: Manca la risorsa InventoryItem su ", name)
		return
		
	sprite_2d.texture = inventory_item.texture
	collision_shape_2d.shape = inventory_item.ground_collision_shape
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body # Salviamo il riferimento al player
		if(body.has_node("Key")):
			body.get_node("Key").show()
		
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_node("Key"):
			body.get_node("Key").hide()
			
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()
			
		current_player=null
			
func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		collect()

func collect() -> void:
	# Aggiungi all'inventario (togli il commento quando Inventory è pronto)
	# Inventory.add_item(inventory_item) 
	
	if current_player:
		if current_player.has_node("Key"):
			current_player.get_node("Key").hide()
		if current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").stop()
	queue_free()
