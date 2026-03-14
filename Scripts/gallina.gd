extends CharacterBody2D

# --- IMPOSTAZIONI DELLA GALLINA ---
@export var speed: float = 30.0
@export var egg_production_time: float = 20.0 # Un po' più veloce della mucca
@export var wander_time_min: float = 1.0
@export var wander_time_max: float = 2.5
@export var idle_time_min: float = 1.5
@export var idle_time_max: float = 4.0
@export var follow_distance: float = 40.0 # Distanza di "blocco"

# --- RIFERIMENTI AI NODI ---
@onready var anim = $AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var timer_l = $TimerL # Timer per l'uovo (mantenuto TimerL per compatibilità scena)
@onready var egg_resource = preload("res://Resources/Egg/egg.tres")

enum State { IDLE, WANDER, FOLLOW }
var current_state = State.IDLE
var move_direction = Vector2.ZERO
var player_in_range: bool = false
var egg_ready: bool = false
var state_timer: float = 0.0

func _ready():
	# Impostazioni fisiche per top-down
	motion_mode = MOTION_MODE_FLOATING
	
	# Configurazione Timer Uovo
	if timer_l:
		timer_l.wait_time = egg_production_time
		timer_l.one_shot = true
		timer_l.timeout.connect(_on_egg_timer_timeout)
		timer_l.start()
	
	# Configurazione ProgressBar
	if progress_bar:
		progress_bar.max_value = egg_production_time
		progress_bar.value = 0
		
		var style_box = progress_bar.get_theme_stylebox("fill").duplicate()
		style_box.bg_color = Color(1.0, 0.9, 0.5, 1) # Giallo chiaro per uovo style
		progress_bar.add_theme_stylebox_override("fill", style_box)

	# Inizializza il primo stato
	_pick_new_state()

func _process(delta):
	# Aggiorna la barra in tempo reale se il timer corre
	if timer_l and not timer_l.is_stopped():
		progress_bar.value = timer_l.wait_time - timer_l.time_left
	elif egg_ready:
		progress_bar.value = egg_production_time
	
	# Controllo per il Segui (Qualsiasi Seme)
	_check_for_follow()
	
	# Gestione timer degli stati (solo se non sta seguendo)
	if current_state != State.FOLLOW:
		if state_timer > 0:
			state_timer -= delta
			if state_timer <= 0:
				_pick_new_state()

func _check_for_follow():
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	
	var holding_seeds = false
	var item_hand = Global.persistent_hand
	var item_food = Global.persistent_food
	
	# Verifica se il player ha un seme in mano o nello slot cibo
	if _is_seed(item_hand) or _is_seed(item_food):
		holding_seeds = true
		
	if holding_seeds:
		var dist = global_position.distance_to(player.global_position)
		if dist < 180.0: # Distanza per sentire l'odore dei semi
			if current_state != State.FOLLOW:
				current_state = State.FOLLOW
				print("La Gallina ha visto i semi!")
	else:
		if current_state == State.FOLLOW:
			current_state = State.IDLE
			_pick_new_state()

func _is_seed(item):
	if item == null: return false
	var n = item.name.to_lower()
	return "seed" in n or "seme" in n or "semino" in n

func _physics_process(_delta):
	var effective_velocity = Vector2.ZERO
	
	if current_state == State.FOLLOW:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dist = global_position.distance_to(player.global_position)
			if dist > follow_distance:
				# Segue solo se il player si muove o se siamo lontani
				if player.velocity.length() > 0.1 or dist > follow_distance + 15.0:
					var dir = (player.global_position - global_position).normalized()
					effective_velocity = dir * speed
			
	elif current_state == State.WANDER:
		effective_velocity = move_direction * speed
	
	velocity = effective_velocity
	
	if velocity.length() > 0:
		if move_and_slide():
			if current_state == State.WANDER:
				_on_collision_detected()
	else:
		# Ferma
		pass
		
	update_animation(velocity)

func update_animation(vel: Vector2):
	if vel.length() < 0.1:
		# Usa l'animazione front_walking come idle (o left_walking e stop)
		anim.play("front_walking")
		anim.stop() 
		return

	if abs(vel.x) > abs(vel.y):
		anim.play("left_walking")
		anim.flip_h = vel.x > 0
	else:
		anim.flip_h = false
		if vel.y > 0:
			anim.play("front_walking")
		else:
			anim.play("back_walking")

func _pick_new_state():
	if current_state == State.FOLLOW: return
	
	if current_state == State.IDLE:
		current_state = State.WANDER
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		
		# Evita player
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < 50.0:
			var dir_to_player = (player.global_position - global_position).normalized()
			var allowed_dirs = []
			for d in directions:
				if d.dot(dir_to_player) < 0.2:
					allowed_dirs.append(d)
			
			if allowed_dirs.size() > 0:
				move_direction = allowed_dirs[randi() % allowed_dirs.size()]
			else:
				move_direction = directions[randi() % directions.size()]
		else:
			move_direction = directions[randi() % directions.size()]
			
		state_timer = randf_range(wander_time_min, wander_time_max)
	else:
		current_state = State.IDLE
		move_direction = Vector2.ZERO
		state_timer = randf_range(idle_time_min, idle_time_max)

func _on_collision_detected():
	if current_state == State.WANDER:
		current_state = State.IDLE
		move_direction = Vector2.ZERO
		state_timer = randf_range(idle_time_min + 0.5, idle_time_max + 1.0)

func _on_egg_timer_timeout():
	egg_ready = true
	print("Uovo pronto per la raccolta!")

func _input(event):
	if player_in_range and egg_ready and event.is_action_pressed("interact"):
		collect_egg()

func collect_egg():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inventory = player.get_node_or_null("Inventory")
		if inventory:
			inventory.add_item(egg_resource, 1)
			print("Uovo raccolto!")
			
			egg_ready = false
			progress_bar.value = 0
			timer_l.start()

# --- GESTIONE AREA INTERAZIONE ---
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if body.has_node("Key"): body.get_node("Key").show()

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_node("Key"): body.get_node("Key").hide()
