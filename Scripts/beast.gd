extends CharacterBody2D

# --- IMPOSTAZIONI DEL NEMICO ---
@export var speed: float = 50.0
@export var chase_distance: float = 200.0
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.0

@export var chases_player: bool = true
@export var patrol_path: Array[Marker2D] = []
@export var patrol_wait_time: float = 1.0

@export var health: int = 100
@export var item_to_drop: InventoryItem

var can_attack: bool = true
var player: Node2D = null
var current_patrol_target = 0
var wait_timer = 0.0

# --- RIFERIMENTI AI NODI ---
@onready var anim = $AnimatedSprite2D
@onready var health_system = $HealthSystem
@onready var progress_bar = $ProgressBar
@onready var hitbox: Area2D = $Area2D

const PICKUP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")
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
	# --- ATTACCO AL PLAYER (STILE UNIFICATO) ---
	if can_attack and hitbox:
		var targets = hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
		for target in targets:
			if target.is_in_group("player"):
				var actual_player = target if target is Player else target.get_parent()
				if actual_player and actual_player.has_method("apply_damage"):
					bite_player(actual_player)
					break 

	var direction = Vector2.ZERO

	# --- IA DI MOVIMENTO ---
	if chases_player and player and can_attack:
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
		# Blocchiamo l'attacco e fermiamo l'animazione
		can_attack = false
		anim.stop()
		
		# --- FIX 1: RISOLUZIONE DELL'INCASTRO (RINCULO) ---
		# Calcoliamo la direzione opposta al player e spingiamo via il mostro
		var knockback_dir = (global_position - target.global_position).normalized()
		global_position += knockback_dir * 15.0 # Lo facciamo rimbalzare indietro di 15 pixel
		
		# Infliggiamo il danno
		target.apply_damage(attack_damage)
		
		# --- FIX 2: RISOLUZIONE DELL'ERRORE ROSSO ---
		# Se il morso ha ucciso il player e il gioco si sta riavviando, 
		# l'albero di gioco (get_tree) sparisce. Interrompiamo lo script per evitare crash!
		if get_tree() == null:
			return
			
		# Aspettiamo il tempo di ricarica
		await get_tree().create_timer(attack_cooldown).timeout
		
		# Riattiviamo l'attacco solo se la bestia esiste ancora
		if get_tree() != null:
			can_attack = true

func apply_damage(amount: int):
	print("La Bestia ha subito ", amount, " danni!")
	
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
	print("Bestia sconfitta!")
	
	# --- LOGICA DEL DROP CON PARABOLA (STILE PINK SLIME) ---
	if item_to_drop != null:
		var loot_drop = PICKUP_ITEM_SCENE.instantiate() as PickUpItem
		
		# 1. Configurazione dati
		loot_drop.inventory_item = item_to_drop
		loot_drop.amount = item_to_drop.stacks if item_to_drop.stacks > 0 else 1
		loot_drop.item_id = "" # Importante per i nemici
		
		# 2. Fix visivi
		loot_drop.z_index = -1
		loot_drop.y_sort_enabled = true
		
		# 3. Parenting
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
		
		print("DEBUG (Enemy Loot): Lanciato con parabola: ", item_to_drop.name)
	# -----------------------------------------------------
	
	queue_free()
