extends CharacterBody2D

class_name PinkSlime
@export var speed: float = 100
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 100.0
@export var chases_player: bool = true
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time: float = 1.0
@export var chase_distance: float = 200.0

@export var damage_to_player: int = 10
@export var attack_cooldown: float = 1.0

@export var health: int = 50
@export var item_to_drop: InventoryItem

# MODIFICA IMPORTANTE: Ora accetta qualsiasi AnimatedSprite2D (Fantasma, Ragno, ecc.)
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var health_system: HealthSystem = $HealthSystem
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var area_collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

const PICKUP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")
var current_patrol_target = 0
var wait_timer = 0.0
var player: Node2D = null
var can_attack: bool = true
var is_in_slime: bool = false
var attack_position: Vector2 = Vector2.ZERO

func set_in_slime(val: bool):
	is_in_slime = val

func _ready() -> void:
	health_system.init(health)
	progress_bar.max_value = health
	progress_bar.value = health
	
	if patrol_path.size() > 0:
		position = patrol_path[0].position
	health_system.died.connect(on_died)
	
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not can_attack:
		# Blocco posizione assoluto: il nemico non si muove di un pixel
		velocity = Vector2.ZERO
		global_position = attack_position
		return

	# --- ATTACCO AL PLAYER (STILE UNIFICATO) ---
	if $Area2D:
		var targets = $Area2D.get_overlapping_bodies() + $Area2D.get_overlapping_areas()
		for target in targets:
			if target.is_in_group("player"):
				var actual_player = target if target is Player else target.get_parent()
				if actual_player and actual_player.has_method("apply_damage"):
					hit_player(actual_player)
					return

	if chases_player and player:
		var distance = global_position.distance_to(player.global_position)
		if distance < chase_distance:
			chase_target_player(delta)
			return

	if patrol_path.size() > 1:
		move_along_path(delta)
	else:
		animated_sprite_2d.play_idle_animation()

func hit_player(target):
	if target.has_method("apply_damage"):
		can_attack = false
		velocity = Vector2.ZERO
		attack_position = global_position # Salviamo la posizione esatta in cui attacca
		
		# Determiniamo la direzione dell'attacco per l'animazione
		var dir_to_player = (target.global_position - global_position).normalized()
		if animated_sprite_2d.has_method("play_attack_animation"):
			animated_sprite_2d.play_attack_animation(dir_to_player)
		
		# Aspettiamo un brevissimo istante per far coincidere il danno con l'inizio dell'animazione
		await get_tree().create_timer(0.1).timeout
		
		if get_tree() == null: return
		
		# Danno ad area: controlliamo tutti i bersagli nell'area hitbox
		if $Area2D:
			var targets = $Area2D.get_overlapping_bodies() + $Area2D.get_overlapping_areas()
			for t in targets:
				if t.is_in_group("player"):
					var actual_player = t if t is Player else t.get_parent()
					if actual_player and actual_player.has_method("apply_damage"):
						actual_player.apply_damage(damage_to_player)
		
		# Aspettiamo il tempo di ricarica totale rimanendo fermi
		await get_tree().create_timer(attack_cooldown).timeout
		
		if get_tree() != null:
			can_attack = true

func chase_target_player(delta: float):
	var direction = (player.global_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(player.global_position)
	
	var effective_speed = speed * (2.0 if is_in_slime else 1.0)
	
	if distance_to_target > 5.0:
		animated_sprite_2d.play_movement_animation(direction)
		velocity = direction * effective_speed 
		move_and_slide()
	else:
		animated_sprite_2d.play_idle_animation()

func apply_damage(damage: int):
	# Qui usiamo il nome corretto del tuo HealthSystem!
	health_system.take_damage(damage)
	progress_bar.value = health_system.current_health

func move_along_path(delta: float):
	var target_position = patrol_path[current_patrol_target].global_position
	var direction = (target_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target_position)
	
	var effective_speed = speed * (2.0 if is_in_slime else 1.0)
	
	if distance_to_target > 5.0:
		animated_sprite_2d.play_movement_animation(direction)
		velocity = direction * effective_speed 
		move_and_slide()
	else:
		animated_sprite_2d.play_idle_animation()
		global_position = target_position 
		wait_timer += delta
		if wait_timer >= patrol_wait_time:
			wait_timer = 0.0
			current_patrol_target = (current_patrol_target + 1) % patrol_path.size()

func on_died():
	# Fermiamo la fisica e facciamo partire l'animazione (che deve chiamarsi "died")
	set_physics_process(false)
	animated_sprite_2d.play("died")
	
	# Godot preferisce che le collisioni vengano disabilitate in modo "sicuro" con set_deferred
	collision_shape_2d.set_deferred("disabled", true)
	area_collision_shape_2d.set_deferred("disabled", true)


# --- NELLO SCRIPT DEL NEMICO (es. PinkSlime.gd) ---

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "died":
		if item_to_drop != null:
			var loot_drop = PICKUP_ITEM_SCENE.instantiate() as PickUpItem
			
			# 1. Configurazione dati
			loot_drop.inventory_item = item_to_drop
			loot_drop.amount = item_to_drop.stacks if item_to_drop.stacks > 0 else 1
			loot_drop.item_id = "" # Importante per i nemici
			
			# 2. Fix visivi (Y-Sort e Z-Index come nel tuo esempio)
			loot_drop.z_index = -1
			loot_drop.y_sort_enabled = true
			
			# 3. Parenting (Lo aggiungiamo al padre del nemico per l'Y-Sort)
			get_parent().add_child(loot_drop)
			
			# 4. Posizionamento iniziale
			var start_pos = global_position
			loot_drop.global_position = start_pos
			
			# 5. Calcolo traiettoria (Offset casuale ridotto)
			var random_offset = Vector2(randf_range(-20.0, 20.0), randf_range(5.0, 15.0))
			var end_pos = start_pos + random_offset
			
			# --- FIX: EVITARE CHE L'OGGETTO FINISCA NEI MURI ---
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
			query.collision_mask = 1 # Livello 1 = Muri/Ostacoli fisici
			var result = space_state.intersect_ray(query)
			if result:
				end_pos = result.position - (random_offset.normalized() * 5.0)
			# ---------------------------------------------------
			
			# --- ANIMAZIONE A PARABOLA PIÙ "CUTE" ---
			
			# Tween per l'asse X (Movimento orizzontale)
			var tween_x = loot_drop.create_tween()
			tween_x.tween_property(loot_drop, "global_position:x", end_pos.x, 0.35)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Tween per l'asse Y (Salitina e rimbalzo)
			var tween_y = loot_drop.create_tween()
			var peak_y = min(start_pos.y, end_pos.y) - 12.0 # Salto più basso
			
			# Fase 1: Salita
			tween_y.tween_property(loot_drop, "global_position:y", peak_y, 0.15)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			# Fase 2: Discesa con rimbalzo
			tween_y.tween_property(loot_drop, "global_position:y", end_pos.y, 0.20)\
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			# ------------------------------------------
			
			print("DEBUG (Enemy Loot): Lanciato con parabola: ", item_to_drop.name)
			
		# Rimuoviamo il nemico
		queue_free()
