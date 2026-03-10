extends Area2D

@export var chest_id: String = "cassa_casa_1"
@export var chest_size: int = 12

# Coordinate spritesheet
@export var x_chiusa: float = 0.0
@export var x_aperta: float = 16.0

var player_in_range: bool = false
var current_player: CharacterBody2D = null
var chest_items: Array = []

@onready var sprite = $Sprite2D

func _ready() -> void:

	print("Chest pronta")

	sprite.region_enabled = true
	sprite.region_rect = Rect2(x_chiusa, 0, 16, 14)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# inizializzazione inventario cassa
	if Global.chests_data.has(chest_id):
		chest_items = Global.chests_data[chest_id]
	else:
		chest_items.resize(chest_size)
		chest_items.fill(null)
		Global.chests_data[chest_id] = chest_items


func _on_body_entered(body: Node2D) -> void:

	print("Qualcosa è entrato nell'area:", body.name)

	if body.is_in_group("player"):
		print("Player vicino alla cassa")

		player_in_range = true
		current_player = body
		
		if body.has_node("Key"):
			body.get_node("Key").show()

		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")


func _on_body_exited(body: Node2D) -> void:

	if body.is_in_group("player"):

		player_in_range = false
		current_player = null
		
		if body.has_node("Key"):
			body.get_node("Key").hide()

		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

		# chiude visivamente la cassa
		sprite.region_rect.position.x = x_chiusa


func _input(event: InputEvent) -> void:

	if player_in_range and event.is_action_pressed("interact"):
		toggle_chest()


func toggle_chest():

	if sprite.region_rect.position.x == x_chiusa:
		sprite.region_rect.position.x = x_aperta
		print("DEBUG: Cassa aperta!")

	else:
		sprite.region_rect.position.x = x_chiusa
		print("DEBUG: Cassa chiusa!")
