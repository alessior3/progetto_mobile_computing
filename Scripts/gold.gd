extends StaticBody2D

@export var bag_id: String = "dungeon1_sacca_oro"
@export var gold_amount: int = 150

var player_in_range: bool = false
var current_player: Node2D = null

@onready var anim = find_child("AnimatedSprite2D", true, false)
@onready var area = find_child("Area2D", true, false)

func _ready() -> void:
	# Se è già stata raccolta in precedenza, la distruggiamo subito
	if bag_id != "" and bag_id in Global.collected_item_ids:
		queue_free()
		return
		
	if anim:
		anim.play("gold_animation")
		
	if area:
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_in_range = true
		current_player = body
		
		# Mostriamo il prompt di interazione a schermo sul player
		if body.has_node("Key"):
			body.get_node("Key").show()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_in_range = false
		current_player = null
		
		# Nascondiamo il prompt di interazione
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and current_player:
		# Consumiamo l'input per evitare interazioni multiple
		get_viewport().set_input_as_handled()
		
		# Nascondiamo i prompt di interazione prima di distruggere l'oggetto
		if current_player.has_node("Key"):
			current_player.get_node("Key").hide()
		if current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").stop()
			
		collect_gold()

func collect_gold() -> void:
	if not current_player: return
	
	# Diamo l'oro al player
	var inv = current_player.get_node_or_null("Inventory")
	if inv:
		inv.gold += gold_amount
		Global.persistent_gold = inv.gold
		inv.gold_changed.emit(inv.gold)
	else:
		# Fallback se non ha il noto Inventory
		Global.persistent_gold += gold_amount
		
	# Aggiorniamo la UI delle monete se presente
	if has_node("/root/OnScreenUi/Control/CoinContainer/CoinCount"):
		var ui_node = get_node("/root/OnScreenUi/Control/CoinContainer/CoinCount")
		ui_node.text = str(Global.persistent_gold)
		
	# Mostriamo il messaggio a schermo tramite DialogueManager
	if has_node("/root/DialogueManager"):
		DialogueManager.show_message("Hai trovato un vecchio sacco d'oro abbandonato contenente " + str(gold_amount) + " monete!", "Sacca d'oro")
		
	# Salviamo lo stato di raccolta per evitare che respawni
	if bag_id != "" and not bag_id in Global.collected_item_ids:
		Global.collected_item_ids.append(bag_id)
		
	# Salviamo il gioco in background per sicurezza
	if Global.has_method("save_game"):
		Global.save_game()
		
	# Eliminiamo la sacca dalla scena
	queue_free()
