extends CharacterBody2D

# --- IMPOSTAZIONI DELLA MUCCA ---
@export var speed: float = 30.0
@export var milk_production_time: float = 30.0
@export var wander_time_min: float = 1.0
@export var wander_time_max: float = 3.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 5.0

# --- RIFERIMENTI AI NODI ---
@onready var anim = $AnimatedSprite2D
@onready var progress_bar = $ProgressBar
@onready var timer_l = $TimerL # Timer per il latte
@onready var milk_resource = preload("res://Resources/Milk/milk.tres")

enum State { IDLE, WANDER }
var current_state = State.IDLE
var move_direction = Vector2.ZERO
var player_in_range: bool = false
var milk_ready: bool = false
var state_timer: float = 0.0

func _ready():
	# Impostazioni fisiche per top-down
	motion_mode = MOTION_MODE_FLOATING
	
	# Configurazione Timer Latte
	if timer_l:
		timer_l.wait_time = milk_production_time
		timer_l.one_shot = true
		timer_l.timeout.connect(_on_milk_timer_timeout)
		timer_l.start()
	
	# Configurazione ProgressBar
	if progress_bar:
		progress_bar.max_value = milk_production_time
		progress_bar.value = 0
		
		var style_box = progress_bar.get_theme_stylebox("fill").duplicate()
		style_box.bg_color = Color(0.2, 0.6, 1.0, 1) # Blu for latte/acqua style
		progress_bar.add_theme_stylebox_override("fill", style_box)

	# Inizializza il primo stato
	_pick_new_state()

func _process(delta):
	# Aggiorna la barra in tempo reale se il timer corre
	if timer_l and not timer_l.is_stopped():
		progress_bar.value = timer_l.wait_time - timer_l.time_left
	elif milk_ready:
		progress_bar.value = milk_production_time
	
	# Gestione timer degli stati
	if state_timer > 0:
		state_timer -= delta
		if state_timer <= 0:
			_pick_new_state()

func _physics_process(_delta):
	if current_state == State.WANDER:
		velocity = move_direction * speed
		if move_and_slide():
			# Se urta qualcosa (mura o player), torna idle
			_on_collision_detected()
	else:
		velocity = Vector2.ZERO
		# Rimosso move_and_slide() in IDLE per evitare di essere trascinata dal player
	
	update_animation(velocity)

func update_animation(vel: Vector2):
	if vel.length() < 0.1:
		# Usa l'animazione left_walking come idle (come beats.gd)
		anim.play("left_walking")
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
	if current_state == State.IDLE:
		current_state = State.WANDER
		# Movimento random NON diagonale
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		
		# Evita di camminare verso il player se troppo vicino
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) < 60.0:
			var dir_to_player = (player.global_position - global_position).normalized()
			var allowed_dirs = []
			for d in directions:
				if d.dot(dir_to_player) < 0.2: # Filtra direzioni che vanno verso il player
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
	# Se urta, forza il passaggio a IDLE per un tempo un po' più lungo per separarsi dal player
	if current_state == State.WANDER:
		current_state = State.IDLE
		move_direction = Vector2.ZERO
		state_timer = randf_range(idle_time_min + 1.0, idle_time_max + 2.0)

func _on_milk_timer_timeout():
	milk_ready = true
	print("Latte pronto per la raccolta!")

func _input(event):
	if player_in_range and milk_ready and event.is_action_pressed("interact"):
		collect_milk()

func collect_milk():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inventory = player.get_node_or_null("Inventory")
		if inventory:
			inventory.add_item(milk_resource, 1)
			print("Latte raccolto!")
			
			# Reset produzione
			milk_ready = false
			progress_bar.value = 0
			timer_l.start()

# --- GESTIONE AREA INTERAZIONE ---
# Nota: Supponiamo che Area2D sia usata per l'interazione ora
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if body.has_node("Key"): body.get_node("Key").show()

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_node("Key"): body.get_node("Key").hide()
