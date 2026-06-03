extends CharacterBody2D

# --- IMPOSTAZIONI DEL NEMICO ---
@export var speed: float = 50.0
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.0
@export var chase_distance: float = 200.0
@export var chases_player: bool = true
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time: float = 1.0

@export var health: int = 70
@export var item_to_drop: InventoryItem

var can_attack: bool = true
var player: Node2D = null
var current_patrol_target = 0
var wait_timer = 0.0
var last_direction: Vector2 = Vector2.DOWN
var attack_position: Vector2 = Vector2.ZERO # Posizione bloccata durante l'attacco

# --- RIFERIMENTI AI NODI ---
@onready var anim = $AnimatedSprite2D
@onready var health_system = $HealthSystem
@onready var progress_bar = $ProgressBar
@onready var hitbox: Area2D = $Area2D

const PICKUP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")


var is_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

func apply_knockback(direction: Vector2):
	is_knocked_back = true
	knockback_velocity = direction * 300.0
	await get_tree().create_timer(0.2).timeout
	if get_tree() != null:
		is_knocked_back = false

func _ready():
	if health_system and progress_bar:
		health_system.init(health_system.max_health)
		progress_bar.max_value = health_system.max_health
		progress_bar.value = health_system.current_health
		
		if health_system.has_signal("damage_taken"):
			health_system.damage_taken.connect(_on_damage_taken)
			
		var style_box = progress_bar.get_theme_stylebox("fill").duplicate()
		style_box.bg_color = Color(1, 0, 0, 1) 
		progress_bar.add_theme_stylebox_override("fill", style_box)

	player = get_tree().get_first_node_in_group("player")
	
	if patrol_path.size() > 0:
		position = patrol_path[0].position

func _physics_process(delta):
	if is_knocked_back:
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1500 * delta)
		return

	if not can_attack:
		# Blocco posizione assoluto: il nemico non si muove di un pixel
		velocity = Vector2.ZERO
		global_position = attack_position
		return

	# --- ATTACCO AL PLAYER (STILE BEAST) ---
	if hitbox:
		var targets = hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
		for target in targets:
			if target.is_in_group("player"):
				var actual_player = target if target is Player else target.get_parent()
				if actual_player and actual_player.has_method("apply_damage"):
					bite_player(actual_player)
					return 

	var direction = Vector2.ZERO

	# --- IA DI MOVIMENTO ---
	if chases_player and player:
		var distance = global_position.distance_to(player.global_position)
		if distance < chase_distance:
			direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			update_animation(direction)
			return

	if patrol_path.size() > 1:
		move_along_path(delta)
	else:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)

func move_along_path(delta: float):
	var target_position = patrol_path[current_patrol_target].global_position
	var direction = (target_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target > 15.0:
		update_animation(direction)
		velocity = direction * speed 
		move_and_slide()
	else:
		update_animation(Vector2.ZERO)
		global_position = target_position 
		wait_timer += delta
		if wait_timer >= patrol_wait_time:
			wait_timer = 0.0
			current_patrol_target = (current_patrol_target + 1) % patrol_path.size()

func update_animation(dir: Vector2):
	if dir == Vector2.ZERO:
		anim.stop()
		return

	last_direction = dir
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("right_walking")
		else:
			anim.play("left_walking")
	else:
		if dir.y > 0:
			anim.play("front_walking")
		else:
			anim.play("back_walking")

func bite_player(target):
	if target.has_method("apply_damage"):
		can_attack = false
		velocity = Vector2.ZERO
		attack_position = global_position # Salviamo la posizione esatta in cui attacca
		
		# Determiniamo la direzione dell'attacco per l'animazione
		var dir_to_player = (target.global_position - global_position).normalized()
		play_attack_animation(dir_to_player)
		
		# Aspettiamo un brevissimo istante per far coincidere il danno con l'inizio dell'animazione
		await get_tree().create_timer(0.1).timeout
		
		if get_tree() == null: return
		
		# Danno ad area: controlliamo tutti i bersagli nell'area hitbox
		if hitbox:
			var targets = hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
			for t in targets:
				if t.is_in_group("player"):
					var actual_player = t if t is Player else t.get_parent()
					if actual_player and actual_player.has_method("apply_damage"):
						actual_player.apply_damage(attack_damage)
		
		# Aspettiamo il tempo di ricarica totale rimanendo fermi
		await get_tree().create_timer(attack_cooldown).timeout
		
		if get_tree() != null:
			can_attack = true

func play_attack_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("attack_right_an")
		else:
			anim.play("attack_left_an")
	else:
		if dir.y > 0:
			anim.play("attack_front_an")
		else:
			anim.play("attack_back_an")

func apply_damage(amount: int):
	print("Red Gladiator ha subito ", amount, " danni!")
	
	if health_system and health_system.has_method("take_damage"):
		health_system.take_damage(amount)
	
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	modulate = Color(1, 1, 1)

func _on_damage_taken(new_health: int):
	if progress_bar:
		progress_bar.value = new_health
		
	if new_health <= 0:
		die()

func die():
	print("Red Gladiator sconfitto!")
	anim.play("dead_an")
	can_attack = false
	set_physics_process(false) 
	
	# --- LOGICA DEL DROP ---
	if item_to_drop != null:
		var loot_drop = PICKUP_ITEM_SCENE.instantiate()
		loot_drop.inventory_item = item_to_drop
		loot_drop.amount = item_to_drop.stacks if item_to_drop.stacks > 0 else 1
		loot_drop.item_id = ""
		loot_drop.z_index = -1
		loot_drop.y_sort_enabled = true
		
		get_parent().add_child(loot_drop)
		var start_pos = global_position
		loot_drop.global_position = start_pos
		
		var random_offset = Vector2(randf_range(-20.0, 20.0), randf_range(5.0, 15.0))
		var end_pos = start_pos + random_offset
		
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
		query.collision_mask = 1 
		var result = space_state.intersect_ray(query)
		if result:
			end_pos = result.position - (random_offset.normalized() * 5.0)
		
		var tween_x = loot_drop.create_tween()
		tween_x.tween_property(loot_drop, "global_position:x", end_pos.x, 0.35)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var tween_y = loot_drop.create_tween()
		var peak_y = min(start_pos.y, end_pos.y) - 12.0
		tween_y.tween_property(loot_drop, "global_position:y", peak_y, 0.15)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_y.tween_property(loot_drop, "global_position:y", end_pos.y, 0.20)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(1.0).timeout
	queue_free()
