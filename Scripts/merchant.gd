extends Sprite2D

class_name Merchant

@export var items_to_buy: Array[InventoryItem]
@export var frase_mercante: String = "Benvenuto, viandante! Dai un'occhiata alle mie merci."

@onready var label: Label = $Label
@onready var shopping_ui = $ShoppingUI as ShoppingUI

var can_trigger_merchant_ui = false

# 0 = Tutto chiuso, 1 = Sto parlando, 2 = Negozio aperto
var stato_interazione = 0 

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
		stato_interazione = 0 # Resetta tutto se scappi via
		if label:
			label.visible = false
		if shopping_ui:
			shopping_ui.visible = false
		if has_node("/root/DialogueManager"):
			DialogueManager.hide()
	
func _process(delta: float) -> void:
	# Controlla in modo super-preciso l'input
	if Input.is_action_just_pressed("interact") and can_trigger_merchant_ui:
		
		if stato_interazione == 0:
			# PASSO 1: Apro il dialogo
			stato_interazione = 1
			if has_node("/root/DialogueManager"):
				DialogueManager.show_message(frase_mercante)
				
		elif stato_interazione == 1:
			# PASSO 2: Chiudo il dialogo e apro il negozio
			stato_interazione = 2
			if has_node("/root/DialogueManager"):
				DialogueManager.hide()
				
			shopping_ui.visible = true
			shopping_ui.setup_buying_grid()
			
		elif stato_interazione == 2:
			# PASSO 3: Negozio già aperto, ignoriamo il tasto interact
			pass
			
	# Tasto per chiudere il negozio e resettare tutto
	if Input.is_action_just_pressed("ui_cancel") and shopping_ui.visible:
		shopping_ui.visible = false
		stato_interazione = 0 # Torniamo allo stato iniziale!
