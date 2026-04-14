extends CanvasLayer
class_name ShoppingUI

var items_to_buy: Array[InventoryItem]
var items_to_sell: Array[InventoryItem]

var selected_item: InventoryItem = null
var current_mode: String = "BUY"

const ROW_SCENE = preload("res://Scenes/UI/shop_item_row.tscn") 

@onready var items_list: VBoxContainer = %ItemsList
@onready var big_icon: TextureRect = %BigIcon
@onready var item_name_label: Label = %ItemName
@onready var item_desc_label: Label = %ItemDescription
@onready var action_btn: Button = %ActionBtn
@onready var shop_gold_label: Label = %ShopGoldLabel
@onready var tab_buy: Button = %TabBuyButton
@onready var tab_sell: Button = %TabSellButton

func _ready() -> void:
	tab_buy.pressed.connect(_on_tab_buy_pressed)
	tab_sell.pressed.connect(_on_tab_sell_pressed)
	action_btn.pressed.connect(_on_action_btn_pressed)
	clear_details_panel()

func setup_buying_grid() -> void: 
	current_mode = "BUY"
	clear_details_panel()
	
	await get_tree().create_timer(0.05).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		var inv = player.get_node_or_null("Inventory")
		if inv:
			if not inv.gold_changed.is_connected(_update_shop_gold):
				inv.gold_changed.connect(_update_shop_gold)
			_update_shop_gold(inv.gold)
		else:
			_update_shop_gold(Global.persistent_gold)
	else:
		_update_shop_gold(Global.persistent_gold)
		
	populate_list(items_to_buy)

func _update_shop_gold(new_amount: int):
	if shop_gold_label:
		shop_gold_label.text = "Oro: " + str(new_amount)

func _on_tab_buy_pressed():
	current_mode = "BUY"
	clear_details_panel()
	populate_list(items_to_buy)

func _on_tab_sell_pressed():
	current_mode = "SELL"
	clear_details_panel()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		items_to_sell = (player.find_child("Inventory") as Inventory).items
	populate_list(items_to_sell)

func populate_list(item_array: Array[InventoryItem]):
	for child in items_list.get_children():
		child.queue_free()
		
	for item in item_array:
		var row = ROW_SCENE.instantiate() as ShopItemRow
		items_list.add_child(row)
		row.setup(item)
		row.item_clicked.connect(func(i): _on_item_selected(i, row))
		
func _on_item_selected(item: InventoryItem, selected_row: ShopItemRow):
	for row in items_list.get_children():
		if row is ShopItemRow:
			row.set_highlight(false)
	
	selected_row.set_highlight(true)
	selected_item = item
	big_icon.texture = item.texture
	item_name_label.text = item.name
	item_desc_label.text = item.get("description") if item.get("description") != null else ""
	
	var total_price = item.price * item.stacks
	var player = get_tree().get_first_node_in_group("player")
	
	if current_mode == "BUY":
		if player and player.get("discount_charges") != null and player.discount_charges > 0:
			var discount_amount = total_price * (player.discount_percentage / 100.0)
			total_price -= int(discount_amount)
			action_btn.text = "BUY - " + str(total_price) + " Gold (DISCOUNT!)"
		else:
			action_btn.text = "BUY - " + str(total_price) + " Gold"
	else:
		action_btn.text = "SELL - " + str(total_price) + " Gold"
		
	action_btn.disabled = false

func clear_details_panel():
	selected_item = null
	big_icon.texture = null
	item_name_label.text = "Seleziona un oggetto"
	item_desc_label.text = ""
	action_btn.text = "..."
	action_btn.disabled = true

func _on_action_btn_pressed():
	if not selected_item: return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var inventory = player.get_node("Inventory") as Inventory
	var cost = selected_item.price * selected_item.stacks
	
	if current_mode == "BUY":
		if "discount_charges" in player and player.discount_charges > 0:
			var discount_amount = cost * (player.discount_percentage / 100.0)
			cost -= int(discount_amount)
			player.discount_charges -= 1
			if player.discount_charges <= 0:
				player.discount_percentage = 0.0
		
		if inventory.has_gold(cost):
			inventory.remove_gold(cost)
			inventory.add_item(selected_item, selected_item.stacks)
			
	elif current_mode == "SELL":
		inventory.items.erase(selected_item)
		var gold_coin_res = load("res://Resources/GoldCoin/gold_coin.tres")
		inventory.add_item(gold_coin_res, cost)
		Global.persistent_items = inventory.items
		
	if current_mode == "BUY":
		populate_list(items_to_buy)
	else:
		_on_tab_sell_pressed() 
		
	clear_details_panel()
	
func _find_row_for_item(item: InventoryItem) -> ShopItemRow:
	for child in items_list.get_children():
		if child is ShopItemRow and child.item == item:
			return child
	return null

func _on_close_button_pressed() -> void:
	hide() # Nasconde l'intera interfaccia del negozio
	print("DEBUG: Shopping UI chiusa correttamente")
	
	# Se il tuo gioco non riprende il movimento da solo, 
	# potresti dover dire al player che può tornare a muoversi qui.
