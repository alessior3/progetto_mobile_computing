extends CharacterBody2D

# --- IMPOSTAZIONI RE RETRO-NERD ---
var is_talking: bool = false
var player_in_range: bool = false
var current_player: Player = null

@export var full_price: int = 1000
@export var discounted_price: int = 50
@export var npc_name: String = "RE BYTE"

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

func start_dialogue():
	is_talking = true
	var dm = DialogueManager
	if not dm: 
		is_talking = false
		return
		
	if Global.has_paid_treasurer:
		dm.show_message(npc_name + ": Ah, il mio SysAdmin preferito! Il Mainframe è online. Cerca di non causare un Kernel Panic là dentro.")
		await dm.dialogue_finished
		is_talking = false
		return

	# Logica sconto: Il Cavolfiore (Cauliflower) dà il buff "discount"
	var has_discount = current_player and current_player.get("discount_charges") != null and current_player.discount_charges > 0
	var price = discounted_price if has_discount else full_price
	
	if has_discount:
		dm.show_message([
			npc_name + ": FERMO! Aspetta... questo profumo... è Cavolfiore fresco?",
			"Per i circuiti di un Commodore 64! Quel pattern di crescita frattale del cavolfiore è identico all'architettura dei miei sogni!",
			"Vedo che anche tu apprezzi l'hardware organico di alta qualità. Solo per oggi, ti darò l'accesso Root per soli " + str(price) + " ori.",
			"È un vero affare, praticamente un Abandonware! Vuoi procedere con l'upload dei fondi?"
		])
	else:
		dm.show_message([
			npc_name + ": ALT! Stai cercando di fare un'intrusione non autorizzata nel mio dominio magnetico?",
			"Questo castello gira su un sistema operativo a 8-bit molto delicato. L'accesso alla sala server richiede un contributo di " + str(price) + " ori per i nuovi condensatori.",
			"Torna quando avrai abbastanza metallo, o se trovi qualcosa che stimoli la mia CPU reale!"
		])
	
	await dm.dialogue_finished
	
	# Controllo fondi
	if current_player.inventory.gold >= price:
		current_player.inventory.gold -= price
		Global.persistent_gold = current_player.inventory.gold
		current_player.inventory.gold_changed.emit(current_player.inventory.gold)
		Global.has_paid_treasurer = true
		dm.show_message(npc_name + ": Pagamento ricevuto. Sincronizzazione permessi in corso... 10%... 100%. La porta è aperta. Che il bit sia con te!")
	else:
		dm.show_message(npc_name + ": Errore 402: Fondi insufficienti. Il mio database dice che sei povero in canna, straniero.")
		
	await dm.dialogue_finished
	is_talking = false
