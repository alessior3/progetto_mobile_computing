extends CharacterBody2D

class_name Merchant2

@export var items_to_buy: Array[InventoryItem]
# NUOVO: Aggiungiamo la frase anche per questo mercante!
@export var frase_mercante: String = "Benvenuto, viandante! Dai un'occhiata alle mie merci."

@onready var indicator: Sprite2D = $Sprite2D
@onready var shopping_ui = $ShoppingUI as ShoppingUI
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var can_trigger_merchant_ui = false

# NUOVO: Il nostro sistema a stati (0 = Niente, 1 = Parla, 2 = Negozio aperto)
var stato_interazione = 0 

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
		stato_interazione = 0 # Resettiamo lo stato se il player scappa
		if indicator:
			indicator.visible = false
		if shopping_ui:
			shopping_ui.visible = false
			
		# Chiudiamo il dialogo se ci allontaniamo
		if has_node("/root/DialogueManager"):
			DialogueManager.hide()

# MODIFICATO: Usiamo _process e gli stati per gestire il doppio tocco e il dialogo
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_trigger_merchant_ui:
		if stato_interazione == 0:
			# --- LOGICA QUEST FLOPPY ---
			var player_has_corrupted = false
			for item in Global.persistent_items:
				if item and item.item_id == "corrupted_floppy":
					player_has_corrupted = true
					break
			
			if Global.has_tried_cave and player_has_corrupted:
				# PASSO 1: Dialogo Quest
				stato_interazione = 3
				if has_node("/root/DialogueManager"):
					DialogueManager.show_message([
						"MERCANTE: Ah, bentornato! Immaginavo che saresti tornato...",
						"Sì, mi aspettavo che quel vecchio floppy fosse rovinato. 
						Quella tecnologia è così delicata!",
						"Si tratta di un Errore CRC, un classico. 
						Ma non temere, c'è una soluzione.",
						"Dovresti portarlo al Mainframe del Castello Blu. 
						Solo una macchina così antica e potente può ripararlo.",
						"Però attento: i server del castello emanano un calore insopportabile. Ti servirà della rigenerazione...",
						"Magari mangia un bel Cavolo prima di attivare il processo, ti terrà in vita mentre la macchina lavora!"
					])
			else:
				# PASSO 1: Mostra la linea di dialogo normale
				stato_interazione = 1
				if has_node("/root/DialogueManager"):
					DialogueManager.show_message(frase_mercante)
				
		elif stato_interazione == 1 or stato_interazione == 3:
			# PASSO 2: Chiudi il dialogo e apri lo shop
			stato_interazione = 2
			if has_node("/root/DialogueManager"):
				DialogueManager.hide()
			if shopping_ui:
				shopping_ui.visible = true
				shopping_ui.setup_buying_grid()

func _process(delta: float) -> void:
	# Tasto per chiudere il negozio
	if Input.is_action_just_pressed("ui_cancel") and shopping_ui and shopping_ui.visible:
		shopping_ui.visible = false
		stato_interazione = 0 # Resettiamo il mercante pronto per parlare di nuovo
