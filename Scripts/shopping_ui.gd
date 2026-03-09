extends CanvasLayer
class_name ShoppingUI

var items_to_buy: Array[InventoryItem]
var items_to_sell: Array[InventoryItem]

var selected_sell_item_indexes: Array[int] = []
var selected_buy_item_indexes: Array[int] = []

const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")

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
		
		# MODIFICA: Il segnale emette (item), noi leghiamo (i).
		# La funzione ricevente dovrà accettare entrambi i parametri.
		buying_slot.slot_clicked.connect(on_buy_slot_clicked.bind(i))
		
	selected_buy_item_indexes.clear()
	buy_button.disabled = true

func setup_selling_grid():
	for child in selling_grid_container.get_children():
		child.queue_free()
	
	items_to_sell = Global.persistent_items
	
	for i in items_to_sell.size():
		var selling_slot = INVENTORY_SLOT_SCENE.instantiate() as InventorySlot
		selling_slot.single_button_press = true
		selling_grid_container.add_child(selling_slot) 
		
		selling_slot.add_item(items_to_sell[i])
		selling_slot.show_price_tag(items_to_sell[i].price * items_to_sell[i].stacks)
		
		# MODIFICA: Stessa logica di bind qui.
		selling_slot.slot_clicked.connect(on_selling_slot_clicked.bind(i))
		
	selected_sell_item_indexes.clear()
	sell_button.disabled = true

# --- LOGICA SELEZIONE ---

# MODIFICA: Ora la funzione accetta l'item emesso (che ignoriamo) e l'indice legato
func on_buy_slot_clicked(_item: InventoryItem, idx: int):
	_toggle_selection(idx, selected_buy_item_indexes, buying_grid_container)
	buy_button.disabled = selected_buy_item_indexes.size() == 0

# MODIFICA: Stessa cosa per la vendita
func on_selling_slot_clicked(_item: InventoryItem, idx: int):
	_toggle_selection(idx, selected_sell_item_indexes, selling_grid_container)
	sell_button.disabled = selected_sell_item_indexes.size() == 0

func _toggle_selection(idx: int, index_array: Array[int], grid: GridContainer):
	if index_array.has(idx):
		index_array.erase(idx)
		grid.get_child(idx).toggle_button_selected_variation(false)
	else:
		index_array.append(idx)
		grid.get_child(idx).toggle_button_selected_variation(true)

# --- TRANSAZIONI ---

func _on_buy_button_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var inventory = player.get_node("Inventory") as Inventory
	
	for i in selected_buy_item_indexes:
		var item = items_to_buy[i]
		var cost = item.price * item.stacks
		
		if inventory.has_gold(cost):
			inventory.remove_gold(cost)
			inventory.add_item(item, item.stacks)
			# Nota: la rimozione da items_to_buy qui dentro un loop 'for i' può causare
			# bug se compri oggetti multipli, dato che gli indici slittano.
			# Per ora lo lasciamo così, ma andrà sistemato se lo shop diventa complesso.
	
	setup_buying_grid()
	setup_selling_grid()

func _on_sell_button_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	var inventory = player.get_node("Inventory") as Inventory
	
	# Usiamo un array temporaneo per evitare errori di indice durante l'erase
	var items_to_remove = []
	for i in selected_sell_item_indexes:
		var item = items_to_sell[i]
		items_to_remove.append(item)
		# Aggiungiamo il valore dell'oggetto all'oro (Wallet)
		# Assicurati che questo percorso corrisponda esattamente al tuo file!
		var gold_coin_res = load("res://Resources/GoldCoin/gold_coin.tres")
		inventory.add_item(gold_coin_res, item.price * item.stacks)
		
	for item in items_to_remove:
		inventory.items.erase(item)
	
	Global.persistent_items = inventory.items # Sincronizzazione persistente
	setup_buying_grid()
	setup_selling_grid()
