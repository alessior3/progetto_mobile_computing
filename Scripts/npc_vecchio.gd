extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var speed: float = 80.0
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var npc_name: String = "Npc Vecchio"
@export var storia_npc: Array[String] = [
	"Ben svegliato, giovane. Finché resti nel villaggio sei al sicuro, ma so che prima o poi vorrai avventurarti oltre i nostri confini.",
	"Devi sapere che le macchine del Mago Oscuro là fuori non sono invincibili. Con il giusto equipaggiamento, chiunque può essere sconfitto.",
	"Dovrai armarti: esplora bene, apri le casse, sconfiggi i mostri. Le armi si riveleranno fondamentali per spezzare le loro barriere.",
	"E non dimenticarti dell'agricoltura! Il cibo giusto non si limita a curarti... alcuni frutti ti conferiranno buff straordinari per essere più veloce o colpire più duramente.",
	"A proposito... dai un'occhiata alla cassa dietro di me. L'ho tenuta al sicuro finora. Aprila e prendi l'arma al suo interno, ne avrai bisogno!"
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
	# NPC statico: non rincorre il giocatore.
	pass

# --- L'AVVISTAMENTO (!) ---
func _on_vision_area_body_entered(body):
	if Global.talked_to_npc_vecchio: return
	
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = true
		player_target = body
		if exclamation_mark:
			exclamation_mark.visible = true

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = false
		player_target = null
		if exclamation_mark:
			exclamation_mark.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not Global.talked_to_npc_vecchio:
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
	
	if has_node("/root/DialogueManager"):
		var dm = get_node("/root/DialogueManager")
		if dm.visible:
			await dm.dialogue_finished
			
		Global.talked_to_npc_vecchio = true
		dm.show_message(storia_npc, npc_name)
