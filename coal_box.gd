extends Area2D

# Trascina qui il tuo nuovo file torch.tres dall'Inspector!
@export var torch_item: InventoryItem 

var player_in_range: bool = false
var current_player: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").stop()

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		try_craft_torch()

func try_craft_torch() -> void:
	if not current_player or not torch_item: return
	
	var inv = current_player.get_node_or_null("Inventory")
	if not inv: return

	# 1. Controlliamo cosa c'è attualmente nella mano
	var equipped_hand = Global.persistent_hand
	
	# ATTENZIONE: Assicurati che "Stick" sia esattamente il nome che hai dato all'oggetto bastone!
	if equipped_hand != null and equipped_hand.name == "Stick":
		print("DEBUG (CoalBox): Stick trovato! Creo la Torcia...")
		
		# 2. Sostituiamo i dati nel salvataggio globale
		inv._save_equipment_to_global("Hand", torch_item)
		
		# 3. Aggiorniamo la UI a schermo
		if inv.on_screen_ui:
			inv.on_screen_ui.equip_item(torch_item, "Hand")
			
		# 4. Aggiorniamo lo sprite nella mano del personaggio
		if inv.equipped_sprite:
			inv.equipped_sprite.texture = torch_item.texture
			inv.equipped_sprite.show()
			
		print("DEBUG (CoalBox): Torcia equipaggiata con successo!")
	else:
		print("DEBUG (CoalBox): Il giocatore non ha uno Stick in mano.")
