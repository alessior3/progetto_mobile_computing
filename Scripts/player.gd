extends CharacterBody2D
class_name Player

# --- NUOVE VARIABILI PER LA CORSA ---
@export var walk_speed: int = 100
@export var run_speed: int = 140
var current_speed: int = 100

var current_dir = "none"
var is_attacking: bool = false

@onready var inventory:Inventory=$Inventory
@onready var health_system: HealthSystem = $HealthSystem
@onready var progress_bar: ProgressBar = $ProgressBar

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
	# --- INIZIALIZZAZIONE DELLA VITA ---
	if health_system and progress_bar:
		health_system.init(health_system.max_health)
		progress_bar.max_value = health_system.max_health
		progress_bar.value = health_system.current_health
		health_system.damage_taken.connect(_on_damage_taken)
		
		# -- CAMBIO COLORE BARRA (Verde per il Player) --
		var style_box = progress_bar.get_theme_stylebox("fill").duplicate()
		style_box.bg_color = Color(0, 1, 0, 1) 
		progress_bar.add_theme_stylebox_override("fill", style_box)
		
	await get_tree().process_frame
	
	# --- 1. PRIORITÀ ASSOLUTA: CARICAMENTO CLOUD ---
	if SaveManager.is_loading_game:
		global_position = SaveManager.loaded_position
		SaveManager.is_loading_game = false
		Global.player_pos = Vector2.ZERO 
		print("Player: Posizionato dal CLOUD")
		
	# --- 2. ENTRATA IN NEGOZIO/CASA ---
	elif get_tree().current_scene.name != "world":
		var spawn_marker = get_tree().current_scene.find_child("Marker2D", true, false)
		if spawn_marker:
			global_position = spawn_marker.global_position
			print("Player: Posizionato sul Marker del negozio")

	# --- 3. RITORNO AL MONDO ESTERNO ---
	elif Global.player_pos != Vector2.ZERO:
		global_position = Global.player_pos
		Global.player_pos = Vector2.ZERO 
		print("Player: Posizionato dalla PORTA")

	# --- Impostazione Dinamica della Direzione ---
	if Global.get("player_facing_dir") != null:
		current_dir = Global.player_facing_dir
	else:
		current_dir = "down" 
		
	play_anim(0)
	set_house(null)

	if has_node("Label"):
		$Label.text = Global.current_username

func _unhandled_input(event):
	if event is InputEventKey and event.is_action_pressed("interact") and house != null:
		house.enter()
		
	# --- SALVATAGGIO CON TASTO K ---
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		Global.player_pos = global_position
		SaveManager.save_game()
		
	# --- ATTACCO CON TASTO L ---
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
	var hand_item = Global.persistent_hand
	if has_node("TorchLight"):
		$TorchLight.visible = (hand_item != null and hand_item.name == "Torch" or hand_item != null and hand_item.name == "Torcia")
	
	if not is_attacking:
		player_movement(delta)
	else:
		move_and_slide()

# ---> MODIFICA FATTA QUI SOTTO <---
func player_movement(delta):
	# Variabile fondamentale: 0 = fermo, 1 = cammina, 2 = corre
	var anim_state = 1 
	
	# Controlliamo se stiamo tenendo premuto il tasto di corsa
	if Input.is_action_pressed("run"):
		current_speed = run_speed
		anim_state = 2 # Diciamo allo script che stiamo correndo
	else:
		current_speed = walk_speed
		anim_state = 1 # Diciamo allo script che stiamo camminando

	# Usiamo la variabile anim_state al posto del "1" fisso!
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
		play_anim(0) # 0 = fermo
		velocity = Vector2.ZERO

	move_and_slide()

func play_anim(movement_state):
	var dir = current_dir
	var anim = $AnimatedSprite2D

	if dir == "right":
		if movement_state == 2:
			anim.flip_h = false # Disattiviamo lo specchio, l'animazione è già per la destra
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
		anim.flip_h = true # Mantengo il flip come lo avevi impostato tu in origine
		if movement_state == 2:
			anim.play("run_front")
		elif movement_state == 1:
			anim.play("walk_front")
		else:
			anim.play("idle_front")
			
	elif dir == "up":
		anim.flip_h = true # Mantengo il flip come lo avevi impostato tu in origine
		if movement_state == 2:
			anim.play("run_back")
		elif movement_state == 1:
			anim.play("walk_back")
		else:
			anim.play("idle_back")

func _on_damage_taken(new_health: int):
	if progress_bar:
		progress_bar.value = new_health
