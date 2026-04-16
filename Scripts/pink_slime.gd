extends CharacterBody2D

class_name PinkSlime
@export var speed: float = 100
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time: float = 1.0
@export var damage_to_player: int = 10

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

func _ready() -> void:
	health_system.init(health)
	progress_bar.max_value = health
	progress_bar.value = health
	
	if patrol_path.size() > 0:
		position = patrol_path[0].position
	health_system.died.connect(on_died)
	
	$Area2D.body_entered.connect(_on_area_2d_body_entered)

func _physics_process(delta: float) -> void:
	if patrol_path.size() > 1:
		move_along_path(delta)

func apply_damage(damage: int):
	# Qui usiamo il nome corretto del tuo HealthSystem!
	health_system.take_damage(damage)
	progress_bar.value = health_system.current_health

func move_along_path(delta: float):
	var target_position = patrol_path[current_patrol_target].global_position
	var direction = (target_position - global_position).normalized()
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target > 5.0:
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
			
			# 5. Calcolo traiettoria (Offset casuale)
			var random_offset = Vector2(randf_range(-35.0, 35.0), randf_range(10.0, 30.0))
			var end_pos = start_pos + random_offset
			
			# --- ANIMAZIONE A PARABOLA (DUE TWEEN) ---
			
			# Tween per l'asse X (Movimento orizzontale costante)
			var tween_x = loot_drop.create_tween()
			tween_x.tween_property(loot_drop, "global_position:x", end_pos.x, 0.4)
			
			# Tween per l'asse Y (Salita e Discesa)
			var tween_y = loot_drop.create_tween()
			var peak_y = min(start_pos.y, end_pos.y) - 25 # Punto più alto del salto
			
			# Fase 1: Salita (QUAD_OUT per rallentare verso l'alto)
			tween_y.tween_property(loot_drop, "global_position:y", peak_y, 0.2)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			# Fase 2: Discesa (QUAD_IN per accelerare verso il basso)
			tween_y.tween_property(loot_drop, "global_position:y", end_pos.y, 0.2)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			# ------------------------------------------
			
			print("DEBUG (Enemy Loot): Lanciato con parabola: ", item_to_drop.name)
			
		# Rimuoviamo il nemico
		queue_free()
func _on_area_2d_body_entered(body: Node2D) -> void:
	# Controlliamo se è il Player usando il nome della classe che hai definito
	print("AREA2D: Ho toccato qualcosa chiamato: ", body.name) # Questo DEVE apparire
	if body is Player:
		print("Il mostro ha colpito il giocatore! Danno: ", damage_to_player)
		
		# Chiamiamo la funzione ufficiale che gestisce TUTTO (difesa, flash rosso, health_system)
		body.apply_damage(damage_to_player)
