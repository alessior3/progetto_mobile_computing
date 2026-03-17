extends Sprite2D

class_name Merchant

@export var items_to_buy: Array[InventoryItem]
@onready var label: Label = $Label
@onready var shopping_ui = $ShoppingUI as ShoppingUI

var can_trigger_merchant_ui = false

func _ready() -> void:
	shopping_ui.items_to_buy = items_to_buy
	shopping_ui.visible = false
	if label:
		label.visible = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		can_trigger_merchant_ui = true
		if label:
			label.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		can_trigger_merchant_ui = false
		if label:
			label.visible = false
		if shopping_ui:
			shopping_ui.visible = false
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_trigger_merchant_ui:
		shopping_ui.visible = true
		shopping_ui.setup_buying_grid()
		
	if event.is_action_pressed("ui_cancel") and shopping_ui.visible:
		shopping_ui.visible = false
