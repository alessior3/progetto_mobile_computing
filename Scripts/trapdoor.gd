extends Area2D

# --- MECCANICA DELLA BOTOLA PER IL TERZO PERCORSO ---
@export var target_scene: String = "res://Scenes/percorso_3.tscn"

var player_in_range: bool = false
var current_player: Player = null
var is_interacting: bool = false

@onready var sprite = get_node_or_null("Sprite2D")

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = true
		current_player = body
		
		# Mostra il tasto di interazione (se supportato dal player)
		if body.has_node("Key"):
			body.get_node("Key").show()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_in_range = false
		current_player = null
		
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not is_interacting:
		get_viewport().set_input_as_handled()
		interact_with_trapdoor()

func interact_with_trapdoor():
	is_interacting = true
	var dm = DialogueManager
	if not dm:
		is_interacting = false
		return
		
	# BLOCCIAMO IL PLAYER DURANTE LE VERIFICHE
	if current_player and "can_move" in current_player:
		current_player.can_move = false
		
	if Global.has_hermit_pass:
		dm.show_message("Usi il lasciapassare elettronico dell'Eremita per sbloccare la botola...", "Sistema")
		await dm.dialogue_finished
		
		# Transizione verso il terzo percorso
		if TransitionChangeManager:
			TransitionChangeManager.change_scene(target_scene)
		else:
			get_tree().change_scene_to_file(target_scene)
	else:
		dm.show_message("La botola di metallo è sigillata da una serratura elettronica avanzata. Serve un'autorizzazione di sicurezza dell'ex-tecnico per sbloccarla.", "Sistema di Sicurezza")
		await dm.dialogue_finished
		
		# Sblocchiamo il player
		if current_player and "can_move" in current_player:
			current_player.can_move = true
			
		is_interacting = false
