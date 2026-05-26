extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var npc_name: String = "Npc Vecchio 2"
@export var storia_npc: Array[String] = [
	"Ehi, giovanotto! Ho sentito in giro che hai una mezza idea di infilarti nel Secondo Dungeon.",
	"Devi sapere che quelle rovine sotterranee sono state invase da una strana creatura viscida...",
	"L'intero pavimento dell'Arena è coperto da una disgustosa melma appiccicosa rosa!",
	"Se ci cammini sopra senza precauzioni, diventerai lento come una lumaca. Sarai un bersaglio facilissimo.",
	"Ti svelo un segreto: coltiva qualcosa nel tuo orticello e prepara un pasto che dia un bel Buff alla Velocità.",
	"Solo così potrai sgusciare via da quella trappola rosa e scivolarci sopra come se fosse ghiaccio!"
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
	if Global.get("talked_to_npc_vecchio2"): return
	
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
	if event.is_action_pressed("interact") and not Global.get("talked_to_npc_vecchio2"):
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
			
		Global.set("talked_to_npc_vecchio2", true)
		dm.show_message(storia_npc, npc_name)
