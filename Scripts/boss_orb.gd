extends Area2D

var speed: float = 250.0 
var direction: Vector2 = Vector2.ZERO
var target: Node2D = null 
var is_exploding: bool = false 
var lifespan: float = 3.5 

@onready var anim_player = $AnimationPlayer

func _ready():
	z_index = 100
	top_level = true
	start_self_destruct()

func start_self_destruct():
	await get_tree().create_timer(lifespan).timeout
	if not is_exploding:
		trigger_explosion()

# Usiamo _physics_process esattamente come nella tua Bestia!
func _physics_process(delta):
	if is_exploding: return

	# --- 1. INSEGUIMENTO CONTINUO E FLUIDO ---
	if target != null and is_instance_valid(target):
		var desired_direction = (target.global_position - global_position).normalized()
		# Continua a sterzare finché non ti prende
		direction = direction.lerp(desired_direction, 4.0 * delta).normalized()

	global_position += direction * speed * delta

	# --- 2. CONTROLLO COLLISIONE "STILE BESTIA" ---
	# Invece di aspettare il segnale, controlliamo chi c'è dentro ad ogni frame
	for body in get_overlapping_bodies():
		if body.is_in_group("player") or body.is_in_group("Player"):
			print("PRESO! Metodo Bestia ha funzionato!")
			
			# Danno
			if body.has_method("_on_damage_taken"):
				body._on_damage_taken(Global.persistent_health - 50)
				
			# Esplosione
			trigger_explosion()
			break # Ferma il ciclo per non fare danno doppio

# --- 3. GESTIONE ESPLOSIONE ---
func trigger_explosion():
	is_exploding = true
	direction = Vector2.ZERO 
	
	if has_node("HitSound"): 
		$HitSound.play()
	
	if anim_player and anim_player.has_animation("explode"):
		anim_player.play("explode")
		await anim_player.animation_finished 
		
	queue_free()
