extends CharacterBody2D
class_name Player

@export var walk_speed: int = 100
@export var run_speed: int = 150
var current_speed: int = 100
var speed_buff_multiplier: float = 1.0
# LIGHT BUFF VARIABLES
var original_torch_scale: float = 1.0
var is_light_buff_active: bool = false

var current_dir = "none"
var is_attacking: bool = false
var is_dead: bool = false

@onready var inventory: Inventory = $Inventory
@onready var health_system: HealthSystem = $HealthSystem
@onready var progress_bar: ProgressBar = $OnScreenUi/ProgressBar

var house = null:
	set = set_house

func set_house(new_house):
	if new_house != null:
		$Key.show()
		$KeyPrompt.play("KeyPrompt")
	else:
		$Key.hide()
		$KeyPrompt.stop()
	house = new_house

func _ready():
	if health_system and progress_bar:
		health_system.init(health_system.max_health)
		progress_bar.max_value = health_system.max_health
		progress_bar.value = health_system.current_health
		health_system.damage_taken.connect(_on_damage_taken)
		
		var style_box = progress_bar.get_theme_stylebox("fill").duplicate()
		style_box.bg_color = Color(0, 1, 0, 1) 
		progress_bar.add_theme_stylebox_override("fill", style_box)
		
	await get_tree().process_frame
	
	if SaveManager.is_loading_game:
		global_position = SaveManager.loaded_position
		SaveManager.is_loading_game = false
		Global.player_pos = Vector2.ZERO 
		print("Player: Posizionato dal CLOUD")
		
	elif get_tree().current_scene.name != "world":
		var spawn_marker = get_tree().current_scene.find_child("Marker2D", true, false)
		if spawn_marker:
			global_position = spawn_marker.global_position
			print("Player: Posizionato sul Marker del negozio")

	elif Global.player_pos != Vector2.ZERO:
		global_position = Global.player_pos
		Global.player_pos = Vector2.ZERO 
		print("Player: Posizionato dalla PORTA")

	# --- IL TRUCCO DEL BIGLIETTINO: APPLICAZIONE PENALITÀ ---
	if Global.has_meta("has_died") and Global.get_meta("has_died") == true:
		print("Penalità di Morte: Svuotamento tasche in corso...")
		Global.reset_inventory_and_gold()
		if inventory:
			for i in range(inventory.items.size()):
				inventory.items[i] = null 
		
		Global.set_meta("has_died", false) 
		SaveManager.save_game()
	# --------------------------------------------------------

	if Global.get("player_facing_dir") != null:
		current_dir = Global.player_facing_dir
	else:
		current_dir = "down" 
		
	play_anim(0)
	set_house(null)

	if has_node("Label"):
		$Label.text = Global.current_username
	
	# Connessione del segnale per il cibo dalla UI su schermo
	if has_node("OnScreenUi"):
		$OnScreenUi.eat_requested.connect(_on_eat_requested)
		
	if has_node("TorchLight"):
		original_torch_scale = $TorchLight.texture_scale

func _unhandled_input(event):
	if is_dead: return
	
	if event is InputEventKey and event.is_action_pressed("interact") and house != null:
		house.enter()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		Global.player_pos = global_position
		SaveManager.save_game()
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_L and not is_attacking:
		var hand_item = Global.persistent_hand
		if hand_item != null and hand_item.get("is_weapon") == true:
			start_attack()

func start_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	
	var anim = $AnimatedSprite2D
	if current_dir == "right":
		anim.flip_h = false
		anim.play("attack_shadowIr_Right")
	elif current_dir == "left":
		anim.flip_h = false
		anim.play("attack_shadowIr_left")
	elif current_dir == "down":
		anim.flip_h = false
		anim.play("attack_shadowIr_front")
	elif current_dir == "up":
		anim.flip_h = false
		anim.play("attack_shadowIr_back")
		
	await get_tree().create_timer(0.15).timeout
	apply_attack_damage()
		
	await anim.animation_finished
	is_attacking = false

func apply_attack_damage():
	var hand_item = Global.persistent_hand
	if hand_item == null or not hand_item.get("is_weapon"):
		return
		
	var attack_damage = hand_item.get("damage")
	if attack_damage == null:
		attack_damage = 1
		
	var attack_range: float = 60.0 
	var attack_angle_deg: float = 180.0 
	
	var attack_dir = Vector2.DOWN
	match current_dir:
		"up": attack_dir = Vector2.UP
		"down": attack_dir = Vector2.DOWN
		"left": attack_dir = Vector2.LEFT
		"right": attack_dir = Vector2.RIGHT

	var root = get_tree().current_scene
	var possible_targets = root.find_children("", "CharacterBody2D", true, false)
	
	for target in possible_targets:
		if target == self:
			continue
			
		if target.has_method("apply_damage"):
			var distance = global_position.distance_to(target.global_position)
			if distance <= attack_range:
				
				var dir_to_target = (target.global_position - global_position).normalized()
				var angle_to_target = rad_to_deg(attack_dir.angle_to(dir_to_target))
				
				if abs(angle_to_target) <= (attack_angle_deg / 2.0):
					print("Player Attacca! Colpito: ", target.name, " Danno: ", attack_damage)
					target.apply_damage(attack_damage)

func _physics_process(delta):
	if is_dead: return
	
	var hand_item = Global.persistent_hand
	if has_node("TorchLight"):
		$TorchLight.visible = (hand_item != null and hand_item.name == "Torch" or hand_item != null and hand_item.name == "Torcia")
	
	if not is_attacking:
		player_movement(delta)
	else:
		move_and_slide()

func player_movement(_delta):
	var anim_state = 1 
	
	if Input.is_action_pressed("run"):
		current_speed = run_speed*speed_buff_multiplier
		anim_state = 2 
	else:
		current_speed = walk_speed*speed_buff_multiplier
		anim_state = 1 

	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_anim(anim_state) 
		velocity.x = current_speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_anim(anim_state)
		velocity.x = -current_speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_anim(anim_state)
		velocity.y = current_speed
		velocity.x = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_anim(anim_state)
		velocity.y = -current_speed
		velocity.x = 0
	else:
		play_anim(0) 
		velocity = Vector2.ZERO

	move_and_slide()

func play_anim(movement_state):
	var dir = current_dir
	var anim = $AnimatedSprite2D

	if dir == "right":
		if movement_state == 2:
			anim.flip_h = false
			anim.play("run_right_side")
		elif movement_state == 1:
			anim.flip_h = true
			anim.play("walk_side")
		else:
			anim.flip_h = true
			anim.play("idle_side")
			
	elif dir == "left":
		anim.flip_h = false
		if movement_state == 2:
			anim.play("run_left_side")
		elif movement_state == 1:
			anim.play("walk_side")
		else:
			anim.play("idle_side")
			
	elif dir == "down":
		anim.flip_h = true 
		if movement_state == 2:
			anim.play("run_front")
		elif movement_state == 1:
			anim.play("walk_front")
		else:
			anim.play("idle_front")
			
	elif dir == "up":
		anim.flip_h = true 
		if movement_state == 2:
			anim.play("run_back")
		elif movement_state == 1:
			anim.play("walk_back")
		else:
			anim.play("idle_back")

func _on_damage_taken(new_health: int):
	print("DEBUG PLAYER: Ricevuto segnale danno! Nuova vita: ", new_health)
	if progress_bar:
		progress_bar.value = new_health
		
	if new_health <= 0:
		die()

# ==========================================
# GESTIONE MORTE DEL PLAYER
# ==========================================
func die():
	if is_dead: return 
	is_dead = true
	
	print("Il Player è morto! Caricamento ultimo salvataggio dal Cloud...")
	
	visible = false
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true) 
	
	Global.set_meta("has_died", true)
	
	var cloud_load_started = SaveManager.load_game() 
	
	if not cloud_load_started:
		print("Test Locale: Riavvio della scena in corso...")
		await get_tree().create_timer(1.0).timeout 
		get_tree().reload_current_scene()

func apply_damage(amount: int):
	if is_dead: return 
	
	print("Il Player ha subito ", amount, " danni!")
	
	if health_system and health_system.has_method("take_damage"):
		health_system.take_damage(amount)
		
	if health_system.current_health > 0 and get_tree() != null:
		modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.2).timeout
		if get_tree() != null:
			modulate = Color(1, 1, 1)

# ==========================================
# GESTIONE CIBO E BUFF
# ==========================================
func _on_eat_requested(item: InventoryItem):
	eat_equipped_food()

func eat_equipped_food():
	var food = Global.persistent_food
	
	if food != null and food.get("is_consumable") == true:
		
		# 1. HEAL THE PLAYER
		if food.get("heal_amount") > 0:
			if health_system and health_system.has_method("heal"):
				health_system.heal(food.heal_amount)
				print("Ate ", food.name, "! Healed for ", food.heal_amount, " HP.")
			else:
				health_system.current_health += food.heal_amount
				if health_system.current_health > health_system.max_health:
					health_system.current_health = health_system.max_health
				_on_damage_taken(health_system.current_health) 
				print("Ate ", food.name, "! Healed for ", food.heal_amount, " HP.")
				
		# 2. PREPARE THE BUFF
		if food.get("buff_type") != "nessuno" and food.get("buff_type") != "":
			print("Obtained buff: ", food.buff_type, " +", food.buff_value, " for ", food.buff_duration, " seconds!")
			apply_buff(food.get("buff_type"), food.get("buff_value"), food.get("buff_duration"))
			
		# 3. CONSUME THE ITEM
		consume_food_item(food)

func consume_food_item(food: InventoryItem):
	food.stacks -= 1
	
	if food.stacks <= 0:
		Global.persistent_food = null
		
		if inventory:
			# MAGIA CORRETTA: Cerchiamo per NOME anziché per istanza
			for i in range(inventory.items.size()):
				if inventory.items[i] != null and inventory.items[i].name == food.name:
					inventory.items[i] = null
					break # Trovato e distrutto, fermiamo il ciclo!
				
			if inventory.on_screen_ui:
				inventory.on_screen_ui.equip_item(null, "Food")
	else:
		if inventory and inventory.on_screen_ui:
			inventory.on_screen_ui.equip_item(food, "Food")
			
	if inventory and inventory.inventory_ui:
		inventory.inventory_ui.update_slots(inventory.items)



# ==========================================
# BUFF MANAGER
# ==========================================
func apply_buff(type: String, value: float, duration: float):
	match type:
		"speed":
			print("RADISH POWER! Sprint doubled!")
			# Convert int (e.g., 2) to float (2.0)
			speed_buff_multiplier = float(value)
			
			# The timer automatically waits for the seconds specified in the .tres file
			await get_tree().create_timer(duration).timeout
			
			# Once the effect ends, return to normal speed
			speed_buff_multiplier = 1.0
			print("Speed buff faded.")
			
		"light":
			print("CARROT POWER! Torch light expanded!")
			if has_node("TorchLight") and not is_light_buff_active:
				is_light_buff_active = true
				
				# Multiply the torch radius by the buff value (e.g., x2.0)
				$TorchLight.texture_scale = original_torch_scale * value
				
				# Wait for 2 minutes (120 seconds)
				await get_tree().create_timer(duration).timeout
				
				# Revert to normal
				$TorchLight.texture_scale = original_torch_scale
				is_light_buff_active = false
				print("Light buff faded.")
		# Future buffs will be added here:
		# "defense": 
		# "light":
		# "damage":
