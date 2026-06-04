extends CharacterBody2D

# --- IMPOSTAZIONI SMANETTONE RETRO ---
var is_talking: bool = false
var player_in_range: bool = false
var current_player: Player = null

@export var full_price: int = 1000
@export var discounted_price: int = 50
@export var npc_name: String = "Marcus Byte"
@export var discount_item: InventoryItem = preload("res://Resources/fullCauliflower/fullCauliflower.tres")

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

func check_discount() -> bool:
	if not current_player:
		return false
		
	# 1. Controllo se il giocatore ha il buff attivo (es. ha mangiato l'oggetto)
	if current_player.get("discount_charges") != null and current_player.discount_charges > 0:
		return true
		
	# 2. Controllo se possiede l'oggetto fisico nell'inventario o negli slot rapidi
	if discount_item:
		if current_player.inventory:
			for item in current_player.inventory.items:
				if item and item.resource_path == discount_item.resource_path:
					return true
			if Global.persistent_food and Global.persistent_food.resource_path == discount_item.resource_path:
				return true
				
	return false

func consume_discount():
	if not current_player:
		return
		
	# Se ha il buff attivo, consuma una carica del buff
	if current_player.get("discount_charges") != null and current_player.discount_charges > 0:
		current_player.discount_charges -= 1
		return
		
	# Altrimenti consuma l'oggetto fisico dall'inventario
	if discount_item and current_player.inventory:
		for i in range(current_player.inventory.items.size()):
			var item = current_player.inventory.items[i]
			if item and item.resource_path == discount_item.resource_path:
				if item.stacks > 1:
					item.stacks -= 1
				else:
					current_player.inventory.items[i] = null
				
				# Aggiorna inventario persistente e UI
				Global.persistent_items = current_player.inventory.items
				if current_player.inventory.inventory_ui:
					current_player.inventory.inventory_ui.update_slots(current_player.inventory.items)
				return
				
		# O dallo slot cibo equipaggiato
		if Global.persistent_food and Global.persistent_food.resource_path == discount_item.resource_path:
			if Global.persistent_food.stacks > 1:
				Global.persistent_food.stacks -= 1
			else:
				Global.persistent_food = null
				if current_player.inventory.on_screen_ui:
					current_player.inventory.on_screen_ui.equip_item(null, "Food")
			return

func start_dialogue():
	is_talking = true
	var dm = DialogueManager
	if not dm: 
		is_talking = false
		return
		
	if Global.has_paid_treasurer:
		dm.show_message("Ehi, bentornato! Il mio supercomputer è online, ma vacci piano... scalda come un dannato! Se rimani lì troppo a lungo vicino allo schermo, finirai arrostito!", npc_name)
		await dm.dialogue_finished
		is_talking = false
		return

	# Logica sconto dinamica ed esportabile
	var has_discount = check_discount()
	var price = discounted_price if has_discount else full_price
	var item_name_label = discount_item.name if discount_item else "Cavolfiore"
	
	if has_discount:
		dm.show_message([
			"EHI! Aspetta un attimo... vedo che hai un " + item_name_label + " con te!",
			"Per tutti i chip di un vecchio Apple II! Quella è la cosa più preziosa e affascinante che abbia visto oggi!",
			"Vedo che te ne intendi di capolavori! Senti, se mi dai quell'oggetto straordinario, ti sblocco il mio supercomputer per soli " + str(price) + " ori.",
			"Praticamente un prezzo simbolico per finanziare la mia collezione di floppy disk. Che ne dici, facciamo questo scambio di dati?"
		], npc_name)
	else:
		dm.show_message([
			"ALT! Non toccare il mio computer! Questo è il mio laboratorio privato di informatica vintage.",
			"Laggiù c'è il mio computer, il più potente del villaggio! Ma consuma e scalda come un dannato! Se vuoi usarlo per ripristinare il tuo floppy disk, mi servono " + str(price) + " ori per coprire i costi di elettricità.",
			"Torna quando avrai abbastanza monete!"
		], npc_name)
	
	await dm.dialogue_finished
	
	# Controllo fondi
	if current_player and current_player.inventory.gold >= price:
		current_player.inventory.gold -= price
		Global.persistent_gold = current_player.inventory.gold
		current_player.inventory.gold_changed.emit(current_player.inventory.gold)
		
		# Consuma l'oggetto o la carica usata per lo sconto
		if has_discount:
			consume_discount()
			
		Global.has_paid_treasurer = true
		dm.show_message([
		"Perfetto! Configuro i permessi di amministratore...", 
		"Fatto! Ora puoi usare il mio supercomputer per ripristinare il floppy. Ma fai attenzione: quando lavora a pieno regime sprigiona un calore infernale!",
		"Se rimani troppo vicino, subirai danni da surriscaldamento!"], npc_name)
	else:
		dm.show_message("Errore 402: Fondi insufficienti per coprire i costi dei condensatori. Torna quando hai caricato il portafoglio virtuale!", npc_name)
		
	await dm.dialogue_finished
	is_talking = false
