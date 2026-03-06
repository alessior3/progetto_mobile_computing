extends CharacterBody2D

class_name Enemy
@export var speed: float = 100
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time = 1.0
@export var damage_to_player = 10

@export var health: int = 50
@export var item_to_drop: InventoryItem

@onready var animated_sprite_2d: EnemyAnimatedSprite2D = $AnimatedSprite2D
@onready var health_system: HealthSystem = $HealthSystem
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var area_collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

const PICKUP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")
var current_patrol_target = 0
var wait_timer = 0.0

func _ready() -> void:
	health_system.init(health)
	progress_bar.max_value = health
	progress_bar.value = health
	
	if patrol_path.size() > 0:
		position = patrol_path[0].position
	health_system.died.connect(on_died)

func _physics_process(delta: float) -> void:
	if patrol_path.size() > 1:
		move_along_path(delta)

func apply_damage(damage: int):
	health_system.apply_damage(damage)
	

func move_along_path(delta: float):
	# 1. Prendiamo le COORDINATE (global_position) del Marker2D, non il nodo intero!
	var target_position = patrol_path[current_patrol_target].global_position
	
	# Usiamo global_position anche per il fantasma per essere più precisi
	var direction = (target_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target_position)
	
	# Se siamo ancora lontani dal bersaglio...
	# (Togliamo il delta da qui per fare un calcolo corretto della distanza)
	if distance_to_target > 5.0: 
		animated_sprite_2d.play_movement_animation(direction)
		
		# 2. Rimuoviamo il * delta! move_and_slide ci pensa da solo in Godot 4
		velocity = direction * speed 
		move_and_slide()
		
	# Se siamo arrivati (o vicinissimi)...
	else:
		animated_sprite_2d.play_idle_animation()
		
		# Ci posizioniamo esattamente sul punto per sicurezza
		global_position = target_position 
		
		# Facciamo partire il timer di attesa
		wait_timer += delta
		if wait_timer >= patrol_wait_time:
			wait_timer = 0.0
			# Passiamo al punto successivo
			current_patrol_target = (current_patrol_target + 1) % patrol_path.size()


func on_died():
	set_physics_process(false)
	animated_sprite_2d.play("died")
	collision_shape_2d.disabled = true
	area_collision_shape_2d.disabled = true
	


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "died":
		var loot_drop = PICKUP_ITEM_SCENE.instantiate() as PickUpItem
		loot_drop.inventory_item = item_to_drop
		loot_drop.stacks = item_to_drop.stacks
		
		get_tree().root.add_child(loot_drop)
		loot_drop.global_position = position
		queue_free()
