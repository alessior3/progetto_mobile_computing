extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var storia_inizio: Array[String] = [
	"Benvenuto nel Villaggio Blu, viaggiatore! Senti, abbiamo un problema urgente.",
	"Dobbiamo accendere il grande falò del villaggio, ma nessuno ha più un accendino! Ormai qua usano tutti la dannata IQOS!",
	"Quella diavoleria scalda e basta, non fa una vera fiamma! Potresti cercare nel percorso successivo se trovi un vecchio accendino a gas?"
]

@export var storia_in_corso: Array[String] = [
	"Ancora niente accendino? Ricorda, prova a cercare nel percorso successivo.",
	"E mi raccomando... se trovi in giro altra gente con la IQOS, per carità, ignorali."
]

@export var storia_consegna: Array[String] = [
	"Incredibile, hai trovato un vero accendino con la fiamma! Grazie mille viaggiatore.",
	"Finalmente potremo scaldarci come ai vecchi tempi. Tieni, prendi queste monete come ricompensa!"
]

@export var storia_completata: Array[String] = [
	"Il falò è magnifico, vero? Altro che quella puzza di IQOS..."
]

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = get_node_or_null("ExclamationMark")
@onready var anim = get_node_or_null("AnimatedSprite2D")

func _ready():
	if exclamation_mark:
		exclamation_mark.visible = false
	if anim:
		anim.play("idle_an")

func _physics_process(delta):
	# NPC statico.
	pass

# --- L'AVVISTAMENTO (!) ---
func _on_vision_area_body_entered(body):
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = true
		player_target = body
		# Mostriamo il punto esclamativo solo se c'è una quest attiva e da completare o se è la prima volta
		if not Global.get("quest_accendino_started") or (Global.get("has_accendino") and not Global.get("quest_accendino_completed")):
			if exclamation_mark:
				exclamation_mark.visible = true

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = false
		player_target = null
		if exclamation_mark:
			exclamation_mark.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_range and not is_talking:
			get_viewport().set_input_as_handled()
			if exclamation_mark:
				exclamation_mark.visible = false
			inizia_dialogo()

func inizia_dialogo():
	is_talking = true
	velocity = Vector2.ZERO
	if anim:
		anim.play("idle_an")
	
	# BLOCCIAMO IL PLAYER!
	if player_target != null and "can_move" in player_target:
		player_target.can_move = false
	
	var current_dialogue: Array[String] = []
	var state = 0
	
	if not Global.get("quest_accendino_started"):
		current_dialogue = storia_inizio
		state = 1
	elif Global.get("quest_accendino_started") and not Global.get("has_accendino"):
		current_dialogue = storia_in_corso
		state = 2
	elif Global.get("has_accendino") and not Global.get("quest_accendino_completed"):
		current_dialogue = storia_consegna
		state = 3
	else:
		current_dialogue = storia_completata
		state = 4
	
	if has_node("/root/DialogueManager"):
		var dm = get_node("/root/DialogueManager")
		if dm.visible:
			await dm.dialogue_finished
			
		dm.show_message(current_dialogue)
		await dm.dialogue_finished
		
		# Logica post-dialogo
		if state == 1:
			Global.set("quest_accendino_started", true)
		elif state == 3:
			Global.set("has_accendino", false)
			Global.set("quest_accendino_completed", true)
			# Diamo la ricompensa
			Global.persistent_gold += 50
			if has_node("/root/OnScreenUi/Control/CoinContainer/CoinCount"):
				var ui_node = get_node("/root/OnScreenUi/Control/CoinContainer/CoinCount")
				ui_node.text = str(Global.persistent_gold)
	
	is_talking = false
	if player_target != null and "can_move" in player_target:
		player_target.can_move = true
