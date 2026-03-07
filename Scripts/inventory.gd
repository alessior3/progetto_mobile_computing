extends Node

class_name Inventory

@onready var inventory_ui:InventoryUI=$"../inventoryUI"

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		print("Tasto I premuto!") # <--- Aggiungi questo
		if inventory_ui:
			inventory_ui.toggle()
		else:
			print("Errore: inventory_ui è NULL!")
