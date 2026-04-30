extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var speed: float = 80.0
var has_spotted_player: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export_multiline var storia_npc: String = "Ehi tu! Fermo lì. Non sai che è pericoloso avventurarsi in queste terre? Un tempo questo era un posto pacifico..."

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = $ExclamationMark
@onready var vision_area = $VisionArea
@onready var anim = $AnimatedSprite2D 

func _ready():
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
# Assicurati di collegare il segnale "body_entered" della tua VisionArea a questa funzione!
func _on_vision_area_body_entered(body):
	# QUESTA RIGA CI DIRÀ LA VERITÀ:
	print("L'NPC ha appena visto entrare nella sua area: ", body.name)
	
	# Controlliamo tutte le combinazioni di maiuscole/minuscole
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		if not has_spotted_player:
			print("IL GIOCATORE È STATO AVVISTATO!")
			has_spotted_player = true
			player_target = body
			# ... resto del codice (velocity = Vector2.ZERO, ecc.)


func inizia_dialogo():
	is_talking = true
	velocity = Vector2.ZERO
	anim.stop()
	
	print("NPC ha raggiunto il player, inizia il dialogo!")
	
	# Usiamo il tuo stesso DialogueManager per fargli dire la frase!
	if has_node("/root/DialogueManager"):
		DialogueManager.show_message(storia_npc)
		
		# (Opzionale): Se il tuo DialogueManager blocca il gioco (pause mode),
		# l'NPC aspetterà in automatico che tu chiuda il dialogo.

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
