extends CharacterBody2D
class_name ExplosivePlant

# --- VARIABILI ESPORTATE ---
@export var max_health: int = 100 
@export var explosion_damage: int = 50 # <-- Alzato a 50! Fa malissimo!
@export var explosion_radius: float = 150.0

# --- RIFERIMENTI AI NODI INTERNI ---
@onready var health_system: HealthSystem = $HealthSystem
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_collision = $Area2D/CollisionShape2D if has_node("Area2D/CollisionShape2D") else null

# Variabile per evitare che prenda colpi mentre sta già esplodendo
var is_dead: bool = false

func _ready():
	health_system.init(max_health)
	progress_bar.max_value = max_health
	progress_bar.value = max_health
	
	if health_system.has_signal("died"):
		health_system.died.connect(_on_plant_died)
		
	anim.animation_finished.connect(_on_animated_sprite_finished)
	
	if anim.sprite_frames.has_animation("bomber_idle"):
		anim.play("bomber_idle")

# SEQUENZA DI MORTE / INNESCO BOMBA
func _on_plant_died():
	if is_dead: return 
	is_dead = true
	
	collision_shape.set_deferred("disabled", true)
	if area_collision:
		area_collision.set_deferred("disabled", true)
	
	progress_bar.visible = false
	
	# PASSO 1: La bomba va SU!
	anim.play("going_up_animation") 

# LA REAZIONE A CATENA DELLE ANIMAZIONI
func _on_animated_sprite_finished():
	
	# PASSO 2: È andata su? Ora va GIÙ!
	if anim.animation == "going_up_animation":
		anim.play("going_down_animation")
		
	# PASSO 3: È andata giù? Ora inizia l'esplosione visiva, ma il DANNO È IMMEDIATO!
	elif anim.animation == "going_down_animation":
		anim.play("explosion_animation")
		apply_explosion_damage() # BOOM! Il colpo arriva adesso!
		
	# PASSO 4: Il fumo si dirada? La pianta sparisce
	elif anim.animation == "explosion_animation":
		queue_free()
		
	# Se era solo un danno normale, torna a respirare (idle)
	elif anim.animation == "hit_animation" and not is_dead:
		if health_system.current_health > 0:
			anim.play("bomber_idle")

# L'ESPLOSIONE VERA E PROPRIA
func apply_explosion_damage():
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= explosion_radius:
			print("BOOM! Danno istantaneo applicato: ", explosion_damage)
			if player.has_method("apply_damage"):
				player.apply_damage(explosion_damage)

# HELPER PER SUBIRE DANNO DAL PLAYER
func apply_damage(damage_amount: int):
	# Se sta già saltando in aria, è invincibile!
	if is_dead: return 
	
	health_system.take_damage(damage_amount)
	progress_bar.value = health_system.current_health
	
	if health_system.current_health > 0:
		anim.play("hit_animation")
