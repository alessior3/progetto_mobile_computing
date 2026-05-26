extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var speed: float = 80.0
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

@export var npc_name: String = "Npc Floppy"
@export var storia_npc: Array[String] = [
	"Mmmh, tu sei quello nuovo, vero? Gira voce che tu voglia raggiungere la botola del vecchio eremita...",
	"L'eremita un tempo era un tecnico del Mago Oscuro. Ha progettato i suoi sistemi di sicurezza. È l'unico che può aprirti la strada per il Terzo Percorso.",
	"Ma so per certo che l'eremita ti aiuterà solo se gli mostri il rarissimo 'Microchip del Mainframe' per dimostrare il tuo valore.",
	"Dicono che il Microchip sia protetto da un terminale corrotto nascosto nelle antiche rovine. Per bypassarlo, avrai bisogno di un vecchio disco dati... un Floppy Disk.",
	"Purtroppo non ne ho, ma sono sicuro che qualcuno qui nel villaggio venda oggetti del genere. Fossi in te, farei un salto dal mercante in fondo al paese."
]

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = $ExclamationMark
@onready var vision_area = $VisionArea
@onready var anim = $AnimatedSprite2D 

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
	if Global.talked_to_npc_floppy: return
	
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
	if event.is_action_pressed("interact") and not Global.talked_to_npc_floppy:
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
			
		Global.talked_to_npc_floppy = true
		dm.show_message(storia_npc, npc_name)
