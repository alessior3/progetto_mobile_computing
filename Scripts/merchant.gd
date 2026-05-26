extends Sprite2D

class_name Merchant

@export var items_to_buy: Array[InventoryItem]
@export var merchant_name: String = "Mercante"
@export var frase_mercante: String = "Benvenuto, viandante! Dai un'occhiata alle mie merci."

@onready var label: Label = $Label
@onready var shopping_ui = $ShoppingUI as ShoppingUI

var can_trigger_merchant_ui = false

# 0 = Tutto chiuso, 1 = Sto parlando, 2 = Negozio aperto, 3 = Dialogo Quest
var stato_interazione = 0 
var current_player: Player = null

func _ready() -> void:
	shopping_ui.items_to_buy = items_to_buy
	shopping_ui.visible = false
	if label:
		label.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		can_trigger_merchant_ui = true
		current_player = body
		if label:
			label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		can_trigger_merchant_ui = false
		stato_interazione = 0 # Resetta tutto se scappi via
		if label:
			label.visible = false
		if shopping_ui:
			shopping_ui.visible = false
		if has_node("/root/DialogueManager"):
			DialogueManager.hide()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_trigger_merchant_ui:
		if stato_interazione == 0:
			# PASSO 1: Dialogo normale
			stato_interazione = 1
			if has_node("/root/DialogueManager"):
				DialogueManager.show_message(frase_mercante, merchant_name)
				
		elif stato_interazione == 1:
			# PASSO 2: Chiudo il dialogo e apro il negozio
			stato_interazione = 2
			if has_node("/root/DialogueManager"):
				DialogueManager.hide()
				
			shopping_ui.visible = true
			shopping_ui.setup_buying_grid()

func _process(delta: float) -> void:
	# Tasto per chiudere il negozio e resettare tutto
	if Input.is_action_just_pressed("ui_cancel") and shopping_ui.visible:
		shopping_ui.visible = false
		stato_interazione = 0 # Torniamo allo stato iniziale!
