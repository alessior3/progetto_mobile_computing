extends StaticBody2D

const PICK_UP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")
const RADISH_ITEM = preload("res://Resources/fullRadish/fullRadish.tres")

@onready var plant = $plant
@onready var radish_timer = $radishTimer
@onready var area_2d = $Area2D

var player_in_zone = false
var current_player: Node2D = null
var is_planted = false
var current_growth_stage = 0
const MAX_GROWTH_STAGE = 5

func _ready():
	# Assicurati che non ci sia nulla piantato all'inizio
	plant.animation = "none"
	is_planted = false
	current_growth_stage = 0
	
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)
	radish_timer.timeout.connect(_on_radish_timer_timeout)

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
		
	# Mostra il prompt solo se la zona è vuota O se la pianta è pronta per essere raccolta
	var should_show = not is_planted or (is_planted and current_growth_stage == MAX_GROWTH_STAGE)
	
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
		# Se non c'è già una pianta, proviamo a piantare
		if not is_planted:
			_try_plant_seed()
		# Se c'è una pianta completamente cresciuta (Opzionale: raccolta)
		elif is_planted and current_growth_stage == MAX_GROWTH_STAGE:
			_harvest_plant()

func _harvest_plant():
	is_planted = false
	current_growth_stage = 0
	plant.animation = "none"
	_update_key_prompt()
	
	var dropped_node = PICK_UP_ITEM_SCENE.instantiate()
	
	dropped_node.z_index = -1
	dropped_node.y_sort_enabled = true
	
	# Usiamo il parent per far apparire l'oggetto nello stesso livello del terreno
	var level_node = get_parent()
	level_node.add_child(dropped_node)
	
	dropped_node.inventory_item = RADISH_ITEM
	dropped_node.item_id = "" # un id vuoto fa sì che l'oggetto non sia persistente
	
	# Facciamo "saltare fuori" l'oggetto
	var start_pos = global_position
	# offset casuale
	var random_offset = Vector2(randf_range(-15.0, 15.0), randf_range(10.0, 20.0))
	var end_pos = start_pos + random_offset
	
	dropped_node.global_position = start_pos
	
	var tween_x = dropped_node.create_tween()
	tween_x.tween_property(dropped_node, "global_position:x", end_pos.x, 0.4)
	
	var tween_y = dropped_node.create_tween()
	var peak_y = min(start_pos.y, end_pos.y) - 20
	tween_y.tween_property(dropped_node, "global_position:y", peak_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(dropped_node, "global_position:y", end_pos.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	print("Ravanello raccolto!")

func _try_plant_seed():
	var hand_item = Global.persistent_hand
	
	if hand_item != null and hand_item.name == "seedRadish":
		# Il giocatore ha il seme equipaggiato.
		
		# Iniziamo la semina
		is_planted = true
		current_growth_stage = 0
		plant.animation = "radishAnimation"
		plant.frame = current_growth_stage
		
		radish_timer.start()
		print("Seme piantato!")
		
		# Nasconde il prompt visto che ora c'è la semina in corso
		_update_key_prompt()
		
		# Rimuoviamo 1 seme dall'inventario
		consume_seed(hand_item)

func consume_seed(seed_item: InventoryItem):
	seed_item.stacks -= 1
	var root = get_tree().current_scene
	var player = root.find_child("player", true, false)
	
	if seed_item.stacks <= 0:
		# Se le quantità sono 0, l'oggetto è finito
		Global.persistent_hand = null
		
		if player and player.has_node("Inventory"):
			var inventory = player.get_node("Inventory")
			
			# Aggiorniamo la UI rimuovendo l'oggetto
			if inventory.on_screen_ui:
				inventory.on_screen_ui.equip_item(null, "Hand")
			if inventory.equipped_sprite:
				inventory.equipped_sprite.hide()
			
			# Fallback se non c'è l'on_screen_ui ma l'UI dell'inventario principale ha bisogno di aggiornarsi
			if inventory.inventory_ui:
				inventory.inventory_ui.update_slots(inventory.items)
	else:
		# L'oggetto ha ancora quantità
		if player and player.has_node("Inventory"):
			var inventory = player.get_node("Inventory")
			# Ricarichiamo l'oggetto nella UI che aggiornerà il testo della quantità!
			if inventory.on_screen_ui:
				inventory.on_screen_ui.equip_item(seed_item, "Hand")
			if inventory.inventory_ui:
				inventory.inventory_ui.update_slots(inventory.items)

func _on_radish_timer_timeout():
	if is_planted and current_growth_stage < MAX_GROWTH_STAGE:
		current_growth_stage += 1
		plant.frame = current_growth_stage
		print("La pianta è cresciuta allo stadio ", current_growth_stage)
		
		if current_growth_stage == MAX_GROWTH_STAGE:
			radish_timer.stop()
			print("La pianta è completamente cresciuta!")
			_update_key_prompt()
