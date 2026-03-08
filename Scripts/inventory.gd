extends Node
class_name Inventory

@onready var inventory_ui: InventoryUI = $"../inventoryUI"
var items: Array[InventoryItem] = []

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		if inventory_ui:
			# Prima aggiorniamo le icone, poi mostriamo la UI
			inventory_ui.update_slots(items) 
			inventory_ui.toggle()
			print("DEBUG: Slot aggiornati con ", items.size(), " oggetti.")
		else:
			print("ERRORE (Inventory): inventory_ui non trovato nel percorso specificato!")

func add_item(item: InventoryItem) -> void:
	if item:
		items.append(item)
		print("DEBUG (Inventory): Oggetto aggiunto: ", item.name)
		print("DEBUG (Inventory): Totale oggetti nell'array: ", items.size())
		
