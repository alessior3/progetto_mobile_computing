extends CharacterBody2D

# --- IMPOSTAZIONI TESORIERE ---
var is_talking: bool = false
var player_in_range: bool = false
var current_player: Player = null

@export var full_price: int = 1000
@export var discounted_price: int = 50
@export var npc_name: String = "TESORIERE"

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = get_node_or_null("ExclamationMark")
@onready var anim = get_node_or_null("AnimatedSprite2D")

func _ready():
	if exclamation_mark:
		exclamation_mark.visible = false
	if anim:
		anim.play("idle_front") # O l'animazione di default

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

func start_dialogue():
	is_talking = true
	var dm = get_node_or_null("/root/DialogueManager")
	if not dm: 
		is_talking = false
		return
		
	if Global.has_paid_treasurer:
		dm.show_message(npc_name + ": Il pagamento è registrato nei log. Puoi accedere al Mainframe. Fa' attenzione al calore laggiù.")
		await dm.dialogue_finished
		is_talking = false
		return

	# Logica sconto: Il Cavolfiore (Cauliflower) dà il buff "discount"
	# Controlliamo il buff del player (cariche di sconto attive)
	var has_discount = current_player.discount_charges > 0
	var price = discounted_price if has_discount else full_price
	
	if has_discount:
		dm.show_message([
			npc_name + ": Oh! Uhm... emani un'aura di... efficienza agronomica. È l'effetto del Cavolfiore, vero?",
			"Raramente vedo qualcuno così ben nutrito di questi tempi. Quel vigore bio-organico mi ha messo di buon umore.",
			"Per un esperto di 'hardware naturale' come te, farò un prezzo di favore: " + str(price) + " ori invece di " + str(full_price) + ".",
			"Vuoi procedere con l'autorizzazione all'accesso della sala server?"
		])
	else:
		dm.show_message([
			npc_name + ": Benvenuto al nodo centrale del Castello Blu. Io gestisco le risorse per il mantenimento del sistema.",
			"L'accesso al Mainframe richiede un'autorizzazione di Livello 0 e una tassa di manutenzione di " + str(price) + " ori.",
			"Sono tempi duri per la tecnologia nostalgia: i condensatori da 3.5 pollici sono diventati rarissimi!"
		])
	
	await dm.dialogue_finished
	
	# Controllo fondi
	if current_player.inventory.gold >= price:
		current_player.inventory.gold -= price
		Global.persistent_gold = current_player.inventory.gold
		current_player.inventory.gold_changed.emit(current_player.inventory.gold)
		Global.has_paid_treasurer = true
		dm.show_message(npc_name + ": Pagamento accettato. I permessi sono stati aggiornati nei settori magnetici. La porta della sala server è ora aperta.")
	else:
		dm.show_message(npc_name + ": Errore 402: Fondi insufficienti. Torna quando avrai accumulato abbastanza metallo prezioso per alimentare il sistema.")
		
	await dm.dialogue_finished
	is_talking = false
