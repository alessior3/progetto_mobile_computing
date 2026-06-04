extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var speed: float = 80.0
var has_spotted_player: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var npc_name: String = "Npc 1"
# --- LA MODIFICA È QUI! Ora è un Array di stringhe (più pagine) ---
@export var storia_npc: Array[String] = [
	"Ehi tu! Avvicinati, viandante. Che ci fai da queste parti?",
	"Non vedi come si sono ridotte le nostre terre? Un tempo queste valli erano pacifiche...",
	"Tutto è iniziato quando abbiamo accettato i 'doni' del Mago Oscuro: strani schermi di vetro e scatole metalliche ronzanti da tenere nelle nostre case.",
	"Ci aveva promesso che ci avrebbero semplificato la vita, ma quelle macchine hanno iniziato a corrompere la terra stessa.",
	"Ora i mostri si annidano in ogni angolo e le strade principali sono sigillate da barriere di pura energia.",
	"Se davvero vuoi fermare tutto questo, l'unica via è attraverso le vecchie rovine sotterranee. Fa' attenzione... laggiù il metallo e la magia sono ormai un'unica, terribile cosa."
]

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = $ExclamationMark
@onready var vision_area = $VisionArea
@onready var anim = $AnimatedSprite2D 

func _ready():
	anim.play("idle_an")
	# Nascondiamo il punto esclamativo all'inizio
	if exclamation_mark:
		exclamation_mark.visible = false

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
			
			# Aggiorna l'animazione di camminata (assicurati che i nomi coincidano con i tuoi!)
			update_animation(direction)
		else:
			# È arrivato davanti al player!
			inizia_dialogo()

# --- L'AVVISTAMENTO (!) ---
func _on_vision_area_body_entered(body):
	print("L'NPC ha appena visto entrare nella sua area: ", body.name)
	
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		if not has_spotted_player and not Global.talked_to_npc1:
			print("IL GIOCATORE È STATO AVVISTATO!")
			has_spotted_player = true
			player_target = body
			
			# 1. Ferma l'NPC
			velocity = Vector2.ZERO
			anim.play("idle_an")
			
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
	anim.play("idle_an")
	
	# BLOCCIAMO IL PLAYER!
	if player_target != null:
		player_target.can_move = false
	
	print("NPC ha raggiunto il player, inizia il dialogo!")
	
	# Passiamo l'Array di frasi al nostro nuovo sistema!
	if has_node("/root/DialogueManager"):
		var dm = DialogueManager
		# Se c'è già un dialogo aperto (es. dell'NPC 3), aspetta che finisca prima di sovrascriverlo!
		if dm.visible:
			await dm.dialogue_finished
			
		Global.talked_to_npc1 = true
		dm.show_message(storia_npc, npc_name)

func update_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("right_walking") # Cambia con il nome della tua animazione destra
		else:
			anim.play("left_walking")  # Cambia con il nome della tua animazione sinistra
	else:
		if dir.y > 0:
			anim.play("front_walking") # Animazione verso il basso
		else:
			anim.play("back_walking")  # Animazione verso l'alto


func _on_vision_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
