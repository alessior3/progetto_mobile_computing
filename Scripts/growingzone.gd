extends StaticBody2D

const PICK_UP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")

# 1. IL NOSTRO DATABASE DELLE PIANTE
# Qui puoi aggiungere tutte le piante del gioco. 
# La chiave (es. "seedRadish") DEVE essere identica al nome (item.name) dell'oggetto seme nel tuo inventario.
var crop_database = {
	"Radish Seed": {
		"grown_item": preload("res://Resources/fullRadish/fullRadish.tres"),
		"animation": "radishAnimation",
		"max_stages": 5
	},
	"Carrot Seed": { 
		# Sostituisci il percorso qui sotto con quello reale della tua carota cresciuta!
		"grown_item": preload("res://Resources/fullCarrot/fullCarrot.tres"), 
		"animation": "carrotAnimation",
		"max_stages": 4 # Magari la carota cresce in meno stadi
	},
	"Wheat Seed": {
		"grown_item": preload("res://Resources/fullWheat/fullWheat.tres"),
		"animation": "wheat_animation",
		"max_stages": 4
	}
}

@onready var plant = $plant
@onready var growth_timer = $GrowthTimer # Ricordati di rinominare il nodo!
@onready var area_2d = $Area2D

var player_in_zone = false
var current_player: Node2D = null
var is_planted = false
var current_growth_stage = 0

# Variabili dinamiche che cambiano in base a cosa piantiamo
var current_crop_info: Dictionary = {}
var max_growth_stage: int = 0

func _ready():
	plant.animation = "none"
	is_planted = false
	current_growth_stage = 0
	
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)
	growth_timer.timeout.connect(_on_growth_timer_timeout)

func _on_area_2d_body_entered(body):
	if body.name == "player" or body is Player:
		player_in_zone = true
		current_player = body
		_update_key_prompt()

func _on_area_2d_body_exited(body):
	if body.name == "player" or body is Player:
		player_in_zone = false
		if current_player and current_player.has_node("Key"):
			current_player.get_node("Key").hide()
		if current_player and current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").stop()
		current_player = null

func _update_key_prompt():
	if not player_in_zone or current_player == null:
		return
		
	# Usiamo la variabile dinamica max_growth_stage
	var should_show = not is_planted or (is_planted and current_growth_stage == max_growth_stage)
	
	if should_show:
		if current_player.has_node("Key"):
			current_player.get_node("Key").show()
		if current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").play("KeyPrompt")
	else:
		if current_player.has_node("Key"):
			current_player.get_node("Key").hide()
		if current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").stop()

func _unhandled_input(event):
	if event is InputEventKey and event.is_action_pressed("interact") and player_in_zone:
		if not is_planted:
			_try_plant_seed()
		elif is_planted and current_growth_stage == max_growth_stage:
			_harvest_plant()

func _try_plant_seed():
	# 1. Ora guardiamo cosa c'è nello slot del cibo!
	var food_item = Global.persistent_food 
	
	# 2. Controlliamo la variabile food_item al posto di hand_item
	if food_item != null and crop_database.has(food_item.name):
		
		current_crop_info = crop_database[food_item.name]
		max_growth_stage = current_crop_info["max_stages"]
		
		is_planted = true
		current_growth_stage = 0
		plant.animation = current_crop_info["animation"]
		plant.frame = current_growth_stage
		
		growth_timer.start()
		print("Piantato seme con ID: ", food_item.name)
		
		_update_key_prompt()
		consume_seed(food_item) # Passiamo l'oggetto cibo alla funzione
func _harvest_plant():
	is_planted = false
	current_growth_stage = 0
	plant.animation = "none"
	_update_key_prompt()
	
	var dropped_node = PICK_UP_ITEM_SCENE.instantiate()
	dropped_node.z_index = -1
	dropped_node.y_sort_enabled = true
	
	var level_node = get_parent()
	level_node.add_child(dropped_node)
	
	# Assegniamo l'oggetto corretto preso dal database!
	dropped_node.inventory_item = current_crop_info["grown_item"]
	dropped_node.item_id = "" 
	
	var start_pos = global_position
	var random_offset = Vector2(randf_range(-15.0, 15.0), randf_range(10.0, 20.0))
	var end_pos = start_pos + random_offset
	
	dropped_node.global_position = start_pos
	
	var tween_x = dropped_node.create_tween()
	tween_x.tween_property(dropped_node, "global_position:x", end_pos.x, 0.4)
	
	var tween_y = dropped_node.create_tween()
	var peak_y = min(start_pos.y, end_pos.y) - 20
	tween_y.tween_property(dropped_node, "global_position:y", peak_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(dropped_node, "global_position:y", end_pos.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	print("Raccolto: ", current_crop_info["grown_item"].name)
	
	# Puliamo la memoria del terreno
	current_crop_info = {}

func consume_seed(seed_item: InventoryItem):
	seed_item.stacks -= 1
	var root = get_tree().current_scene
	var player = root.find_child("player", true, false)
	
	if seed_item.stacks <= 0:
		Global.persistent_food = null
		
		if player and player.has_node("Inventory"):
			var inventory = player.get_node("Inventory")
			
			# MAGIA CORRETTA: Cerchiamo per NOME
			for i in range(inventory.items.size()):
				if inventory.items[i] != null and inventory.items[i].name == seed_item.name:
					inventory.items[i] = null
					break # Trovato e distrutto!
			
			if inventory.on_screen_ui:
				inventory.on_screen_ui.equip_item(null, "Food")
			
			if inventory.inventory_ui:
				inventory.inventory_ui.update_slots(inventory.items)
	else:
		if player and player.has_node("Inventory"):
			var inventory = player.get_node("Inventory")
			if inventory.on_screen_ui:
				inventory.on_screen_ui.equip_item(seed_item, "Food")
			if inventory.inventory_ui:
				inventory.inventory_ui.update_slots(inventory.items)

func _on_growth_timer_timeout():
	if is_planted and current_growth_stage < max_growth_stage:
		current_growth_stage += 1
		plant.frame = current_growth_stage
		
		if current_growth_stage == max_growth_stage:
			growth_timer.stop()
			_update_key_prompt()
