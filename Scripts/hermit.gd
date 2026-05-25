extends CharacterBody2D

signal reached_terminal

# --- IMPOSTAZIONI EREMITA EX-TECNICO ---
var is_talking: bool = false
var player_in_range: bool = false
var current_player: Player = null

@export var npc_name: String = "Eremita ex-Tecnico"
@export var card_item: InventoryItem = preload("res://Resources/SecurityCard/security_card.tres")

# --- CINEMATICA DEL MOVIMENTO ---
@export var terminal_position: Vector2 = Vector2(48, 0) # Offset relativo rispetto alla posizione di partenza dell'eremita (es. Vector2(48, 0) sposta di 48px a destra)
@export var walk_speed_cutscene: float = 65.0

var is_moving_to_terminal: bool = false
var target_pos: Vector2 = Vector2.ZERO

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = get_node_or_null("ExclamationMark")
@onready var anim = get_node_or_null("AnimatedSprite2D")

func _ready():
	print("[DEBUG - Hermit] NPC caricato e pronto. card_item caricato da: ", card_item.resource_path if card_item else "NULL")
	if exclamation_mark:
		exclamation_mark.visible = false
	if anim:
		anim.play("idle_front")

func _physics_process(delta: float) -> void:
	if is_moving_to_terminal:
		var dir = (target_pos - global_position).normalized()
		var dist = global_position.distance_to(target_pos)
		if dist > 3.0:
			velocity = dir * walk_speed_cutscene
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			global_position = target_pos
			is_moving_to_terminal = false
			print("[DEBUG - Hermit] Terminale raggiunto in fisica! Emissione segnale reached_terminal.")
			reached_terminal.emit()

func _on_vision_area_body_entered(body):
	print("[DEBUG - Hermit] VisionArea rilevata entrata di un body: ", body, " (is Player: ", body is Player, ")")
	if body is Player:
		player_in_range = true
		current_player = body
		print("[DEBUG - Hermit] Player nel raggio dell'Eremita! (player_in_range = true)")
		if exclamation_mark:
			exclamation_mark.visible = true

func _on_vision_area_body_exited(body):
	print("[DEBUG - Hermit] VisionArea rilevata uscita di un body: ", body, " (is Player: ", body is Player, ")")
	if body is Player:
		player_in_range = false
		current_player = null
		print("[DEBUG - Hermit] Player uscito dal raggio dell'Eremita! (player_in_range = false)")
		if exclamation_mark:
			exclamation_mark.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("[DEBUG - Hermit] Rilevato input 'interact' globale. player_in_range: ", player_in_range, ", is_talking: ", is_talking)
		if player_in_range and not is_talking:
			print("[DEBUG - Hermit] Condizioni interazione soddisfatte. Avvio dialogo...")
			get_viewport().set_input_as_handled()
			start_dialogue()

func check_card() -> bool:
	print("[DEBUG - Hermit] Esecuzione check_card()...")
	if not current_player:
		print("[DEBUG - Hermit] check_card fallito: current_player è NULL!")
		return false
	if not current_player.inventory:
		print("[DEBUG - Hermit] check_card fallito: current_player non ha un nodo inventory!")
		return false
	
	print("[DEBUG - Hermit] Contenuto inventario del player:")
	for i in range(current_player.inventory.items.size()):
		var item = current_player.inventory.items[i]
		if item:
			print("  - Slot ", i, ": ", item.name, " (ID: ", item.item_id, ", Path: ", item.resource_path, ")")
			if card_item and item.item_id == card_item.item_id:
				print("    -> CORRISPONDENZA TROVATA col target ID: ", card_item.item_id)
				return true
		else:
			print("  - Slot ", i, ": Vuoto")
	
	print("[DEBUG - Hermit] Nessun microchip corrispondente trovato nell'inventario.")
	return false

func consume_card():
	if not current_player:
		return
	if card_item and current_player.inventory:
		for i in range(current_player.inventory.items.size()):
			var item = current_player.inventory.items[i]
			if item and item.item_id == card_item.item_id:
				if item.stacks > 1:
					item.stacks -= 1
				else:
					current_player.inventory.items[i] = null
				
				# Aggiorna inventario persistente e UI
				Global.persistent_items = current_player.inventory.items
				if current_player.inventory.inventory_ui:
					current_player.inventory.inventory_ui.update_slots(current_player.inventory.items)
				return

func start_dialogue():
	print("[DEBUG - Hermit] start_dialogue() avviata. has_hermit_pass: ", Global.has_hermit_pass)
	is_talking = true
	var dm = DialogueManager
	if not dm: 
		print("[DEBUG - Hermit] ERRORE: DialogueManager Autoload NON trovato!")
		is_talking = false
		return
		
	# BLOCCIAMO IL PLAYER!
	if current_player and "can_move" in current_player:
		print("[DEBUG - Hermit] Blocco il player durante il dialogo.")
		current_player.can_move = false
		
	if Global.has_hermit_pass:
		print("[DEBUG - Hermit] Sblocco già avvenuto in precedenza (Global.has_hermit_pass = true). Mostro dialogo finale.")
		dm.show_message("La botola è sbloccata. Scendi pure nel terzo percorso. Ti prego, sconfiggi il Boss e libera questa terra una volta per tutte!", npc_name)
		await dm.dialogue_finished
		if current_player and "can_move" in current_player:
			current_player.can_move = true
		is_talking = false
		print("[DEBUG - Hermit] Dialogo terminato. Riaperto movimento.")
		return

	var has_card = check_card()
	print("[DEBUG - Hermit] Risultato check_card per il dialogo: ", has_card)
	
	if has_card:
		print("[DEBUG - Hermit] Il giocatore possiede il microchip. Avvio sblocco e dialogo associato.")
		dm.show_message([
			"Aspetta... cos'è quel bagliore dorato che tieni in mano?!",
			"Quello... è l'antico e preziosissimo Microchip del Mainframe del secondo settore!",
			"Non posso crederci... sei riuscito davvero a bypassare la crittografia binaria dei socket, a sconfiggere i sistemi di sicurezza e a recuperare questo pezzo unico?!",
			"Ascolta... io sono un ex-tecnico informatico al servizio del Boss. Sono fuggito perché non potevo più sopportare la sua spietatezza, e mi sono nascosto qui nei boschi.",
			"La botola di metallo in fondo alla stanza conduce direttamente alle vecchie condutture del terzo settore, ma è protetta da un blocco elettronico avanzato.",
			"Hai dimostrato di avere coraggio e abilità straordinarie... Custodisci con cura quel microchip raro come trofeo del tuo valore!"
		], npc_name)
		await dm.dialogue_finished
		
		# Annuncia lo sblocco e si muove
		dm.show_message("Ora ti apro la botola dal terminale. Guarda...", npc_name)
		await dm.dialogue_finished
		
		# Calcola la posizione globale del terminale sommando l'offset relativo alla posizione corrente dell'eremita
		target_pos = global_position + terminal_position
			
		is_moving_to_terminal = true
		print("[DEBUG - Hermit] Avvio movimento verso il terminale in: ", target_pos)
		
		# Attendiamo che l'eremita raggiunga il terminale
		await reached_terminal
		print("[DEBUG - Hermit] Eremita arrivato al terminale! Inizio digitazione...")
		
		# Simuliamo la digitazione e il bypass elettronico per 1.5 secondi
		await get_tree().create_timer(1.5).timeout
		
		# Il lasciapassare viene sbloccato qui (attiva visivamente la botola aperta)
		Global.has_hermit_pass = true
		print("[DEBUG - Hermit] Lasciapassare sbloccato e assegnato con successo!")
		
		# Dialogo finale di commiato
		dm.show_message("Fatto. La botola ora è sbloccata! Va' là sotto, e metti fine alla follia del Boss!", npc_name)
		await dm.dialogue_finished
		
	else:
		print("[DEBUG - Hermit] Il giocatore NON possiede il microchip. Avvio dialogo ostile.")
		dm.show_message([
			"Chi sei?! Cosa vuoi da me?! Non dovresti essere qui!",
			"Vattene, questa è solo una vecchia capanna abbandonata nei boschi! Non c'è nulla di interessante qui.",
			"Fila via prima che i droni di pattuglia del Boss traccino i tuoi segnali biometrici!"
		], npc_name)
		await dm.dialogue_finished

	# SBLOCCHIAMO IL PLAYER ALLA FINE
	if current_player and "can_move" in current_player:
		print("[DEBUG - Hermit] Ripristino il movimento del player.")
		current_player.can_move = true
		
	is_talking = false
	print("[DEBUG - Hermit] Dialogo terminato.")
