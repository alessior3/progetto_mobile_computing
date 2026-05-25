extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var storia_npc: Array[String] = [
	"Ehi, aspetta un attimo... ma tu sei quello di cui tutti parlano! Colui che ha superato il labirinto del Primo Dungeon e sconfitto il guardiano!",
	"Le voci sulle tue eroiche gesta sono arrivate fin qui. Sei l'unica speranza che ci rimane contro il Mago Oscuro.",
	"Ma non esultare troppo in fretta. Se stai andando verso il Secondo Dungeon, preparati al peggio. Quel posto è molto diverso dalle vecchie rovine.",
	"È una vera e propria Arena. Nessun labirinto in cui nascondersi, nessuna via di fuga. Solo ondate di macchine spietate progettate per annientarti.",
	"Al centro troverai un grande Terminale di Controllo. Dovrai attivarlo e sopravvivere finché l'hackeraggio non sarà completo. Che la Dea della Rete vegli su di te!"
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
	if Global.get("talked_to_npc_villaggio2"): return
	
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
	if event.is_action_pressed("interact") and not Global.get("talked_to_npc_villaggio2"):
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
			
		Global.set("talked_to_npc_villaggio2", true)
		dm.show_message(storia_npc)
