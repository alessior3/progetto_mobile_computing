extends CharacterBody2D

class_name Merchant2

@export var items_to_buy: Array[InventoryItem]
@onready var indicator: Sprite2D = $Sprite2D
@onready var shopping_ui = $ShoppingUI as ShoppingUI
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var can_trigger_merchant_ui = false

func _ready() -> void:
	if shopping_ui:
		shopping_ui.items_to_buy = items_to_buy
		shopping_ui.visible = false
	
	if indicator:
		indicator.visible = false
		
	if anim:
		anim.play("front_animation")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		can_trigger_merchant_ui = true
		if indicator:
			indicator.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		can_trigger_merchant_ui = false
		if indicator:
			indicator.visible = false
		if shopping_ui:
			shopping_ui.visible = false

func _input(event: InputEvent) -> void:
	# L'interazione avviene premendo il tasto interazione (E)
	if event.is_action_pressed("interact") and can_trigger_merchant_ui:
		if shopping_ui:
			shopping_ui.visible = true
			shopping_ui.setup_buying_grid()
		
	if event.is_action_pressed("ui_cancel") and shopping_ui and shopping_ui.visible:
		shopping_ui.visible = false
