extends CanvasLayer

class_name ShoppingUI

var items_to_buy: Array[InventoryItem]
var items_to_sell: Array[InventoryItem]

var selected_sell_item_indexes: Array[int] = []
var selected_buy_item_indexes: Array[int] = []

const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")

# La moneta per ora è disattivata finché non la crei
# var gold_coin_inventory_item = preload("res://Resources/GoldCoin/gold_coin.tres")

@onready var buying_grid_container: GridContainer = %BuyingGridContainer
@onready var selling_grid_container: GridContainer = %SellingGridContainer

@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton


func setup_buying_grid():
	for child in buying_grid_container.get_children():
		child.queue_free()
	
	for i in items_to_buy.size():
		var buying_slot = INVENTORY_SLOT_SCENE.instantiate() as InventorySlot
		buying_slot.single_button_press = true
		buying_grid_container.add_child(buying_slot)
		buying_slot.add_item(items_to_buy[i])
		buying_slot.show_price_tag(items_to_buy[i].price * items_to_buy[i].stacks)
		buying_slot.slot_clicked.connect(on_buy_slot_clicked.bind(i)) # Corretto 'connect'
		
func on_buy_slot_clicked(idx: int):
	if selected_buy_item_indexes.has(idx):
		buying_grid_container.get_child(idx).toggle_button_selected_variation(false)
		selected_buy_item_indexes.erase(idx)
	else:
		buying_grid_container.get_child(idx).toggle_button_selected_variation(true) # Corretto 'variation'
		selected_buy_item_indexes.append(idx)
		
	buy_button.disabled = selected_buy_item_indexes.size() == 0

func setup_selling_grid():
	for child in selling_grid_container.get_children():
		child.queue_free()
	
	for i in items_to_sell.size():
		var selling_slot = INVENTORY_SLOT_SCENE.instantiate() as InventorySlot
		selling_slot.single_button_press = true
		buying_grid_container.add_child(selling_slot) # NOTA: Stai aggiungendo a buying_grid invece di selling_grid, lascio così com'era nel tuo codice ma controlla!
		selling_slot.add_item(items_to_sell[i])
		selling_slot.show_price_tag(items_to_sell[i].price * items_to_sell[i].stacks)
		selling_slot.slot_clicked.connect(on_selling_slot_clicked.bind(i)) # Corretto 'connect'
		
		
func on_selling_slot_clicked(idx: int):
	if selected_sell_item_indexes.has(idx):
		selling_grid_container.get_child(idx).toggle_button_selected_variation(false)
		selected_sell_item_indexes.erase(idx)
	else:
		selling_grid_container.get_child(idx).toggle_button_selected_variation(true) # Corretto 'variation'
		selected_sell_item_indexes.append(idx)
		
	sell_button.disabled = selected_sell_item_indexes.size() == 0



func _on_buy_button_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	var player_inventory = player.find_child("Inventory") as Inventory
	var merchant = get_tree().get_first_node_in_group("merchant") as Merchant
	
	var indexes_to_remove = []

	for i in selected_buy_item_indexes:
		var item_to_buy = items_to_buy[i]
		var total_cost = item_to_buy.price * item_to_buy.stacks
		
		if player_inventory.has_gold(total_cost): 
			player_inventory.remove_gold(total_cost)
			player_inventory.add_item(item_to_buy, item_to_buy.stacks)
			
			merchant.items_to_buy.erase(item_to_buy)
			
			# --- DA DECOMMENTARE QUANDO AVRAI LA MONETA ---
			# var gold_coin_clone = gold_coin_inventory_item.duplicate()
			# gold_coin_clone.stacks = total_cost
			# merchant.items_to_buy.append(gold_coin_clone)
			
			buying_grid_container.get_child(i).queue_free()
			indexes_to_remove.append(i)
		else:
			print("Oro insufficiente per comprare: ", item_to_buy.name)

	for index in indexes_to_remove:
		selected_buy_item_indexes.erase(index)
		
	setup_buying_grid()
	setup_selling_grid()
	buy_button.disabled = true

func _on_sell_button_pressed() -> void:
	var merchant = get_tree().get_first_node_in_group("merchant") as Merchant
	var player = get_tree().get_first_node_in_group("player") as Player
	var inventory = (player.find_child("Inventory") as Inventory)

	for i in selected_sell_item_indexes:
		var item_to_sell = items_to_sell[i]
		selling_grid_container.get_child(i).queue_free()

		var current_items_in_player_inventory = inventory.items
		current_items_in_player_inventory.erase(item_to_sell)
		inventory.items = current_items_in_player_inventory

		inventory.clear_inventory_slot(i)
		selected_sell_item_indexes.erase(i)
		merchant.items_to_buy.append(item_to_sell)

		# --- DA DECOMMENTARE QUANDO AVRAI LA MONETA ---
		# var gold_to_add_to_player = item_to_sell.price * item_to_sell.stacks
		# inventory.add_item(gold_coin_inventory_item, gold_to_add_to_player)

	items_to_buy = merchant.items_to_buy
	setup_buying_grid()
	setup_selling_grid()
	sell_button.disabled = true
