extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var speed: float = 80.0
var has_spotted_player: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var storia_npc: Array[String] = [
	"Ehi tu! Fermo lì.",
	"Non sai che è pericoloso avventurarsi in queste terre?",
    "Un tempo questo era un posto pacifico..."
]

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = $ExclamationMark
@onready var vision_area = $VisionArea
@onready var anim = $AnimatedSprite2D 

func _ready():
	# Nascondiamo il punto esclamativo all'inizio
	if exclamation_mark:
		exclamation_mark.visible = false
	if anim:
		anim.play("idle_an")

func _physics_process(delta):
	if is_talking: return
	
	# FASE DI INSEGUIMENTO DOPO L'AVVISTAMENTO
	if has_spotted_player and player_target != null:
		var distanza = global_position.distance_to(player_target.global_position)
		
		# Cammina verso il player finché non arriva vicino (40 pixel)
		if distanza > 40.0:
			var direction = (player_target.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			
			# Aggiorna l'animazione di camminata (per NpcVecchio usiamo sempre walk_an)
			if anim:
				anim.play("walk_an")
		else:
			# È arrivato davanti al player!
			inizia_dialogo()

# --- L'AVVISTAMENTO (!) ---
func _on_vision_area_body_entered(body):
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		if not has_spotted_player:
			has_spotted_player = true
			player_target = body
			
			# 1. Ferma l'NPC
			velocity = Vector2.ZERO
			if anim:
				anim.stop()
			
			# 2. Mostra il punto esclamativo
			if exclamation_mark:
				exclamation_mark.visible = true
				
			# 3. Pausa drammatica
			set_physics_process(false)
			await get_tree().create_timer(1.0).timeout
			
			# 4. Nasconde il punto esclamativo e inizia a correre verso di te
			if exclamation_mark:
				exclamation_mark.visible = false
				
			set_physics_process(true)


func inizia_dialogo():
	is_talking = true
	velocity = Vector2.ZERO
	if anim:
		anim.play("idle_an")
	
	# BLOCCIAMO IL PLAYER!
	if player_target != null and "can_move" in player_target:
		player_target.can_move = false
	
	if has_node("/root/DialogueManager"):
		get_node("/root/DialogueManager").show_message(storia_npc)

func _on_vision_area_body_exited(body: Node2D) -> void:
	pass
