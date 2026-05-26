extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var has_spotted_player: bool = false
var is_talking: bool = false

@export var npc_name: String = "Npc Prete 1"
@export_multiline var storia_npc: String = "Pace a te, figliolo. Cosa ti porta in questo luogo sacro in tempi così bui?"

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = $ExclamationMark
@onready var anim = $AnimatedSprite2D
@onready var vision_area = $VisionArea

func _ready():
	# Inizia con l'animazione di schiena
	if anim:
		anim.play("back_an")
	
	# Nasconde il punto esclamativo all'inizio
	if exclamation_mark:
		exclamation_mark.visible = false

func _on_vision_area_body_entered(body):
	# Se l'NPC ha già visto il player, non facciamo nulla
	if has_spotted_player:
		return
		
	# Controlliamo se il corpo che è entrato è il Player
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		print("Prete ha visto il player!")
		has_spotted_player = true
		
		# 1. Cambia animazione in idle_an (si gira o si ferma)
		if anim:
			anim.play("idle_an")
			
		# 2. Mostra il punto esclamativo
		if exclamation_mark:
			exclamation_mark.visible = true
			
		# 3. Breve pausa prima di iniziare a parlare (opzionale ma consigliato per effetto scenico)
		await get_tree().create_timer(0.5).timeout
		
		# 4. Nasconde il punto esclamativo quando inizia a parlare (come negli altri NPC)
		if exclamation_mark:
			exclamation_mark.visible = false
			
		# 5. Inizia il dialogo
		inizia_dialogo()

func inizia_dialogo():
	is_talking = true
	
	# Blocchiamo il movimento dell'NPC (se ne avesse)
	velocity = Vector2.ZERO
	
	print("Il Prete inizia a parlare...")
	
	var dm = null
	# Cerchiamo il DialogueManager
	if has_node("/root/DialogueManager"):
		dm = get_node("/root/DialogueManager")
	
	if dm:
		dm.show_message(storia_npc, npc_name)
		# Aspettiamo che il dialogo finisca
		await dm.dialogue_finished
		
		# Ripristiniamo l'animazione back_an
		if anim:
			anim.play("back_an")
		
		is_talking = false
		# Se vuoi che possa parlare di nuovo, scommenta la riga sotto:
		# has_spotted_player = false
	else:
		print("Errore: DialogueManager non trovato!")

func _on_vision_area_body_exited(body: Node2D) -> void:
	pass
