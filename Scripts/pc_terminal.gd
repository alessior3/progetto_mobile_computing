extends Area2D

@export var required_gem_id: String = "gem_green"
@export var pc_id: String = "pc_1"

var is_on: bool = false
var player_in_range: bool = false
var current_player: Node2D = null
var is_talking: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Carichiamo lo stato
	if Global.get(pc_id + "_on"):
		is_on = true
	_update_visuals()

func _update_visuals():
	if is_on:
		modulate = Color(0, 1, 0) # Verde quando acceso
	else:
		modulate = Color(1, 0.3, 0.3) # Rossiccio quando spento

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		if body.has_node("Key"):
			body.get_node("Key").show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		if body.has_node("Key"):
			body.get_node("Key").hide()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_talking and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		is_talking = true
		if is_on:
			_show_message(["SISTEMA ONLINE.", "Connessione al mainframe stabilita."])
			await DialogueManager.dialogue_finished
			is_talking = false
			return
			
		if _player_has_gem(required_gem_id):
			is_on = true
			Global.set(pc_id + "_on", true)
			_update_visuals()
			_show_message(["Gemma accettata!", "Avvio sequenza di boot...", "PC ACCESO."])
			await DialogueManager.dialogue_finished
			is_talking = false
		else:
			_show_message(["ACCESSO NEGATO.", "Richiesta gemma: " + required_gem_id, "Torna quando avrai la gemma."])
			await DialogueManager.dialogue_finished
			is_talking = false

func _player_has_gem(gem_id: String) -> bool:
	if not current_player or not current_player.has_node("Inventory"):
		return false
	var inv = current_player.get_node("Inventory")
	for item in inv.items:
		if item != null and item.item_id == gem_id:
			return true
	return false

func _show_message(text_array: Array[String]):
	var pc_name = "Computer Verde"
	if required_gem_id == "gem_purple":
		pc_name = "Computer Viola"
	elif required_gem_id == "gem_red":
		pc_name = "Computer Rosso"
	DialogueManager.show_message(text_array, pc_name)
