extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var npc_name: String = "Npc Villaggio 2 House"
@export var storia_npc: Array[String] = [
	"Ehi, viaggiatore! Sei capitato nel giorno giusto! Hai per caso saputo la grande notizia?",
	"Il Villaggio Rosso ha umiliato il Villaggio Blu nel grande derby annuale! Che goduria... Forza Rosso sempre e abbasso i puffi del Villaggio Blu!",
	"Quelli del Villaggio Blu sanno solo lamentarsi e piangere, mentre noi abbiamo la stoffa dei campioni! E a proposito di sfide impossibili...",
	"Ho sentito in giro che vuoi infilarti in quel tritacarne del Secondo Dungeon. Amico mio, con quell'armetta che ti ritrovi farai solo il solletico alle macchine di quell'Arena.",
	"Ti conviene fare un giro in paese e procurarti un'arma più pesante. Un vero tifoso del Rosso non scende mai in campo senza l'equipaggiamento giusto!"
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
	if Global.get("talked_to_npc_villaggio2_house"): return
	
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
	if event.is_action_pressed("interact") and not Global.get("talked_to_npc_villaggio2_house"):
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
			
		Global.set("talked_to_npc_villaggio2_house", true)
		dm.show_message(storia_npc, npc_name)
