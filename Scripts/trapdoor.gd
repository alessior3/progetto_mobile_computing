extends Area2D

# --- MECCANICA DELLA BOTOLA PER IL TERZO PERCORSO ---
@export var target_scene: String = "res://Scenes/percorso_3.tscn"

var player_in_range: bool = false
var current_player: Player = null
var is_interacting: bool = false

var original_rect: Rect2
var is_open: bool = false

@onready var sprite = get_node_or_null("Sprite2D")

func _ready() -> void:
	print("[DEBUG - Trapdoor] Botola caricata e pronta. Target scene: ", target_scene)
	if sprite and sprite.region_enabled:
		original_rect = sprite.region_rect
		print("[DEBUG - Trapdoor] Rettangolo originale salvato: ", original_rect)
		_update_sprite()
		
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if Global.has_hermit_pass and not is_open:
		print("[DEBUG - Trapdoor] _process ha rilevato lo sblocco! Aggiorno sprite a 'Aperta'.")
		_update_sprite()

func _update_sprite():
	if sprite and sprite.region_enabled:
		if Global.has_hermit_pass:
			# Sposta la coordinata Y in basso di un'altezza pari a quella dello sprite (subito sotto nello spritesheet)
			var new_rect = Rect2(original_rect.position.x, original_rect.position.y + original_rect.size.y, original_rect.size.x, original_rect.size.y)
			sprite.region_rect = new_rect
			is_open = true
			print("[DEBUG - Trapdoor] Impostato rect per botola APERTA: ", new_rect)
		else:
			sprite.region_rect = original_rect
			is_open = false
			print("[DEBUG - Trapdoor] Impostato rect per botola CHIUSA: ", original_rect)

func _on_body_entered(body: Node2D) -> void:
	print("[DEBUG - Trapdoor] Rilevato body_entered: ", body, " (is Player: ", body is Player, ")")
	if body is Player:
		player_in_range = true
		current_player = body
		print("[DEBUG - Trapdoor] Player entrato nell'Area della botola!")
		
		# Mostra il tasto di interazione (se supportato dal player)
		if body.has_node("Key"):
			body.get_node("Key").show()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	print("[DEBUG - Trapdoor] Rilevato body_exited: ", body, " (is Player: ", body is Player, ")")
	if body is Player:
		player_in_range = false
		current_player = null
		print("[DEBUG - Trapdoor] Player uscito dall'Area della botola!")
		
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("[DEBUG - Trapdoor] Rilevato input 'interact' globale. player_in_range: ", player_in_range, ", is_interacting: ", is_interacting)
		if player_in_range and not is_interacting:
			print("[DEBUG - Trapdoor] Condizioni interazione soddisfatte. Eseguo interact_with_trapdoor().")
			get_viewport().set_input_as_handled()
			interact_with_trapdoor()

func interact_with_trapdoor():
	print("[DEBUG - Trapdoor] interact_with_trapdoor() avviata. Global.has_hermit_pass: ", Global.has_hermit_pass)
	is_interacting = true
	var dm = DialogueManager
	if not dm:
		print("[DEBUG - Trapdoor] ERRORE: DialogueManager Autoload NON trovato!")
		is_interacting = false
		return
		
	# BLOCCIAMO IL PLAYER DURANTE LE VERIFICHE
	if current_player and "can_move" in current_player:
		print("[DEBUG - Trapdoor] Blocco il player durante l'azione.")
		current_player.can_move = false
		
	if Global.has_hermit_pass:
		print("[DEBUG - Trapdoor] Lasciapassare attivo! Avvio transizione scena.")
		dm.show_message("Usi il lasciapassare elettronico dell'Eremita per sbloccare la botola...", "Sistema")
		await dm.dialogue_finished
		
		# Transizione verso il terzo percorso
		if TransitionChangeManager:
			print("[DEBUG - Trapdoor] Uso TransitionChangeManager per caricare la scena: ", target_scene)
			TransitionChangeManager.change_scene(target_scene)
		else:
			print("[DEBUG - Trapdoor] TransitionChangeManager assente. Cambio scena diretto a: ", target_scene)
			get_tree().change_scene_to_file(target_scene)
	else:
		print("[DEBUG - Trapdoor] Accesso negato: lasciapassare assente.")
		dm.show_message("La botola di metallo è sigillata da una serratura elettronica avanzata. Serve un'autorizzazione di sicurezza dell'ex-tecnico per sbloccarla.", "Sistema di Sicurezza")
		await dm.dialogue_finished
		
		# Sblocchiamo il player
		if current_player and "can_move" in current_player:
			print("[DEBUG - Trapdoor] Ripristino il movimento del player.")
			current_player.can_move = true
			
		is_interacting = false
		print("[DEBUG - Trapdoor] Interazione conclusa.")
