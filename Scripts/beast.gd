extends CharacterBody2D

# --- IMPOSTAZIONI DEL NEMICO ---
@export var speed: float = 50.0
@export var chase_distance: float = 200.0
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.0

var can_attack: bool = true
var player: Node2D = null

# --- RIFERIMENTI AI NODI ---
@onready var anim = $AnimatedSprite2D
@onready var health_system = $HealthSystem
@onready var progress_bar = $ProgressBar
@onready var hitbox: Area2D = $Area2D

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

func _physics_process(delta):
	var direction = Vector2.ZERO

	# --- IA DI INSEGUIMENTO MODIFICATA ---
	# Si muove verso il player SOLO se non sta ricaricando un attacco
	if player and can_attack:
		var distance = global_position.distance_to(player.global_position)
		
		# Rimosso il limite "> 15.0", ora va fino a sbatterci contro!
		if distance < chase_distance:
			direction = (player.global_position - global_position).normalized()

	velocity = direction * speed
	move_and_slide()
	
	update_animation(direction)
	
	# --- ATTACCO AL PLAYER ---
	if can_attack and hitbox:
		for body in hitbox.get_overlapping_bodies():
			if body.is_in_group("player"):
				bite_player(body)
				break 

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
	queue_free()
