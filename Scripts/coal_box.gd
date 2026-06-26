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

	# 1. Controlliamo prima se lo Stick è nell'inventario
	var stick_in_inv_idx = -1
	for i in range(inv.items.size()):
		if inv.items[i] != null and inv.items[i].name == "Stick":
			stick_in_inv_idx = i
			break
			
	var equipped_hand = Global.persistent_hand
	var has_crafted = false
	
	if stick_in_inv_idx != -1:
		print("DEBUG (CoalBox): Stick trovato nello zaino! Lo consumo...")
		inv.items[stick_in_inv_idx].stacks -= 1
		if inv.items[stick_in_inv_idx].stacks <= 0:
			inv.items[stick_in_inv_idx] = null
		Global.persistent_items = inv.items
		if inv.inventory_ui:
			inv.inventory_ui.update_slots(inv.items)
		has_crafted = true
	elif equipped_hand != null and equipped_hand.name == "Stick":
		print("DEBUG (CoalBox): Stick trovato nella mano! Lo consumo...")
		equipped_hand.stacks -= 1
		if equipped_hand.stacks <= 0:
			inv._save_equipment_to_global("Hand", null)
			if inv.on_screen_ui:
				inv.on_screen_ui.equip_item(null, "Hand")
			if inv.equipped_sprite:
				inv.equipped_sprite.hide()
		else:
			inv._save_equipment_to_global("Hand", equipped_hand)
			if inv.on_screen_ui:
				inv.on_screen_ui.equip_item(equipped_hand, "Hand")
		has_crafted = true
	else:
		print("DEBUG (CoalBox): Nessuno Stick trovato.")
		return
		
	if has_crafted:
		# 2. Se c'era già un oggetto nelle Pozioni, lo rimettiamo nello zaino per non perderlo
		var old_potion = Global.persistent_potions
		if old_potion != null:
			if not inv._insert_item_into_array(old_potion):
				inv._drop_physical_item(old_potion)
			Global.persistent_items = inv.items
			if inv.inventory_ui:
				inv.inventory_ui.update_slots(inv.items)
		
		# 3. Equipaggiamo la Torcia nello slot Pozioni
		# Per assicurarci che si comporti correttamente, duplichiamo la risorsa
		var new_torch = torch_item.duplicate()
		new_torch.slot_type = "Potions"
		new_torch.stacks = 1
		inv._save_equipment_to_global("Potions", new_torch)
		if inv.on_screen_ui:
			inv.on_screen_ui.equip_item(new_torch, "Potions")
			
		print("DEBUG (CoalBox): Torcia creata ed equipaggiata nello slot Pozioni con successo!")
