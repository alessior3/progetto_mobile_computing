extends CharacterBody2D

# --- IMPOSTAZIONI EREMITA EX-TECNICO ---
var is_talking: bool = false
var player_in_range: bool = false
var current_player: Player = null

@export var npc_name: String = "Eremita ex-Tecnico"
@export var card_item: InventoryItem = preload("res://Resources/SecurityCard/security_card.tres")

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = get_node_or_null("ExclamationMark")
@onready var anim = get_node_or_null("AnimatedSprite2D")

func _ready():
	if exclamation_mark:
		exclamation_mark.visible = false
	if anim:
		anim.play("idle_front")

func _on_vision_area_body_entered(body):
	if body is Player:
		player_in_range = true
		current_player = body
		if exclamation_mark:
			exclamation_mark.visible = true

func _on_vision_area_body_exited(body):
	if body is Player:
		player_in_range = false
		current_player = null
		if exclamation_mark:
			exclamation_mark.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not is_talking:
		get_viewport().set_input_as_handled()
		start_dialogue()

func check_card() -> bool:
	if not current_player:
		return false
	if card_item and current_player.inventory:
		for item in current_player.inventory.items:
			if item and item.resource_path == card_item.resource_path:
				return true
	return false

func consume_card():
	if not current_player:
		return
	if card_item and current_player.inventory:
		for i in range(current_player.inventory.items.size()):
			var item = current_player.inventory.items[i]
			if item and item.resource_path == card_item.resource_path:
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
	is_talking = true
	var dm = DialogueManager
	if not dm: 
		is_talking = false
		return
		
	# BLOCCIAMO IL PLAYER!
	if current_player and "can_move" in current_player:
		current_player.can_move = false
		
	if Global.has_hermit_pass:
		dm.show_message("La botola è sbloccata. Scendi pure nel terzo percorso. Ti prego, sconfiggi il Boss e libera questa terra una volta per tutte!", npc_name)
		await dm.dialogue_finished
		if current_player and "can_move" in current_player:
			current_player.can_move = true
		is_talking = false
		return

	var has_card = check_card()
	
	if has_card:
		dm.show_message([
			"Aspetta... cos'è quel bagliore dorato che tieni in mano?!",
			"Quello... è l'antico e preziosissimo Microchip del Mainframe del secondo settore!",
			"Non posso crederci... sei riuscito davvero a bypassare la crittografia binaria dei socket, a sconfiggere i sistemi di sicurezza e a recuperare questo pezzo unico?!",
			"Ascolta... io sono un ex-tecnico informatico al servizio del Boss. Sono fuggito perché non potevo più sopportare la sua spietatezza, e mi sono nascosto qui nei boschi.",
			"La botola di metallo in fondo alla stanza conduce direttamente alle vecchie condutture del terzo settore, ma è protetta da un blocco elettronico avanzato.",
			"Hai dimostrato di avere coraggio e abilità straordinarie... Custodisci con cura quel microchip raro come trofeo del tuo valore! Intanto, ho appena inviato un impulso di bypass dal mio terminale.",
			"La botola ora è sbloccata. Va' là sotto, e metti fine alla follia del Boss!"
		], npc_name)
		await dm.dialogue_finished
		
		# Il giocatore tiene il microchip raro nell'inventario; assegniamo solo il lasciapassare
		Global.has_hermit_pass = true
		
	else:
		dm.show_message([
			"Chi sei?! Cosa vuoi da me?! Non dovresti essere qui!",
			"Vattene, questa è solo una vecchia capanna abbandonata nei boschi! Non c'è nulla di interessante qui.",
			"Fila via prima che i droni di pattuglia del Boss traccino i tuoi segnali biometrici!"
		], npc_name)
		await dm.dialogue_finished

	# SBLOCCHIAMO IL PLAYER ALLA FINE
	if current_player and "can_move" in current_player:
		current_player.can_move = true
		
	is_talking = false
