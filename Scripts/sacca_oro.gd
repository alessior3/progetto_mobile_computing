extends Area2D

@export var bag_id: String = "sacca_oro_dungeon1"
@export var gold_amount: int = 100

var player_in_range: bool = false
var current_player: CharacterBody2D = null

func _ready() -> void:
	# Se l'oro è già stato raccolto in precedenza, rimuovi la sacca immediatamente
	if bag_id != "" and bag_id in Global.collected_item_ids:
		queue_free()
		return
		
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_in_range = true
		current_player = body
		
		# Mostra il prompt d'interazione sul giocatore
		if body.has_node("Key"):
			body.get_node("Key").show()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_in_range = false
		current_player = null
		
		# Nascondi il prompt d'interazione
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and current_player:
		get_viewport().set_input_as_handled()
		
		# Nascondi subito i prompt prima della distruzione del nodo
		if current_player.has_node("Key"):
			current_player.get_node("Key").hide()
		if current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").stop()
			
		collect_gold()

func collect_gold() -> void:
	if not current_player: return
	
	# Aggiungi oro all'inventario del giocatore
	var inv = current_player.get_node_or_null("Inventory")
	if inv:
		inv.gold += gold_amount
		Global.persistent_gold = inv.gold
		inv.gold_changed.emit(inv.gold)
	else:
		# Fallback globale
		Global.persistent_gold += gold_amount
		
	# Aggiorna il contatore grafico dell'oro a schermo
	if has_node("/root/OnScreenUi/Control/CoinContainer/CoinCount"):
		var ui_node = get_node("/root/OnScreenUi/Control/CoinContainer/CoinCount")
		ui_node.text = str(Global.persistent_gold)
		
	# Mostra un messaggio a schermo pulito
	if has_node("/root/DialogueManager"):
		DialogueManager.show_message("Hai trovato " + str(gold_amount) + " monete d'oro!", "Sacca d'oro")
		
	# Registra la raccolta nel salvataggio per evitare respawn
	if bag_id != "" and not bag_id in Global.collected_item_ids:
		Global.collected_item_ids.append(bag_id)
		
	if Global.has_method("save_game"):
		Global.save_game()
		
	queue_free()
