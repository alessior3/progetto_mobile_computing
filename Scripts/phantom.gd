extends CharacterBody2D

class_name PhantomEnemy

@export var speed: float = 100
@export var patrol_path: Array[Marker2D] = []

# --- FIX 1: TIPIZZAZIONE FLOAT ---
@export var patrol_wait_time: float = 1.0
# ---------------------------------

@export var chases_player: bool = false
@export var chase_distance: float = 200.0

@export var damage_to_player: int = 10
@export var attack_cooldown: float = 1.0

@export var health: int = 50
@export var item_to_drop: InventoryItem

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var health_system: HealthSystem = $HealthSystem
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var area_collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var attack_area: Area2D = $Area2D

const PICKUP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")
var current_patrol_target = 0
var wait_timer = 0.0
var player: Node2D = null
var can_attack: bool = true

func _ready() -> void:
	health_system.init(health)
	progress_bar.max_value = health
	progress_bar.value = health
	
	if patrol_path.size() > 0:
		position = patrol_path[0].position
	health_system.died.connect(on_died)
	
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# --- ATTACCO AL PLAYER (STILE BESTIA) ---
	if can_attack and attack_area:
		var targets = attack_area.get_overlapping_bodies() + attack_area.get_overlapping_areas()
		for target in targets:
			if target.is_in_group("player"):
				var actual_player = target if target is Player else target.get_parent()
				if actual_player and actual_player.has_method("apply_damage"):
					hit_player(actual_player)
					break

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
		
		# Effetto di rimbalzo (knockback) per evitare che si incastrino
		var knockback_dir = (global_position - target.global_position).normalized()
		global_position += knockback_dir * 15.0
		
		print(name, " ha colpito il giocatore!")
		target.apply_damage(damage_to_player)
		
		if get_tree() == null: return
		
		await get_tree().create_timer(attack_cooldown).timeout
		
		if get_tree() != null:
			can_attack = true

func chase_target_player(delta: float):
	var direction = (player.global_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(player.global_position)
	
	if distance_to_target > 15.0:
		animated_sprite_2d.play_movement_animation(direction)
		velocity = direction * speed 
		move_and_slide()
	else:
		animated_sprite_2d.play_idle_animation()

func apply_damage(damage: int):
	# --- FIX 2: NOME FUNZIONE AGGIORNATO ---
	health_system.take_damage(damage)
	# ---------------------------------------
	progress_bar.value = health_system.current_health

func move_along_path(delta: float):
	var target_position = patrol_path[current_patrol_target].global_position
	var direction = (target_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target_position)
	
	# --- PULIZIA: Ho rimosso il blocco if/else duplicato qui ---
	if distance_to_target > 15.0:
		animated_sprite_2d.play_movement_animation(direction)
		velocity = direction * speed 
		move_and_slide()
	else:
		animated_sprite_2d.play_idle_animation()
		global_position = target_position 
		wait_timer += delta
		if wait_timer >= patrol_wait_time:
			wait_timer = 0.0
			current_patrol_target = (current_patrol_target + 1) % patrol_path.size()

func on_died():
	set_physics_process(false)
	
	animated_sprite_2d.play_death_animation()
	
	collision_shape_2d.set_deferred("disabled", true)
	area_collision_shape_2d.set_deferred("disabled", true)

func _on_animated_sprite_2d_animation_finished() -> void:
	var anim_name = animated_sprite_2d.animation
	if anim_name == "death_animation_left" or anim_name == "death_animation_right":
		
		# --- FIX 3: BLOCCO DEL DROP E ISTANZIAZIONE SICURA ---
		if item_to_drop != null:
			var loot_drop = PICKUP_ITEM_SCENE.instantiate() as PickUpItem
			loot_drop.inventory_item = item_to_drop
			loot_drop.stacks = item_to_drop.stacks
			
			get_tree().root.add_child(loot_drop)
			loot_drop.global_position = position
		# -----------------------------------------------------
		
		queue_free()
