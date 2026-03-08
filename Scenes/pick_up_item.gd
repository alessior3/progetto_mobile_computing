extends Area2D

class_name PickUpItem

@export var inventory_item : InventoryItem

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var player_in_range : bool = false
var current_player : CharacterBody2D = null # Memorizziamo chi è entrato

func _ready() -> void:
	# Sicurezza: se dimentichi di mettere lo stick.tres, non crasha il gioco
	if inventory_item == null:
		print("ATTENZIONE: Manca la risorsa InventoryItem su ", name)
		return
		
	sprite_2d.texture = inventory_item.texture
	collision_shape_2d.shape = inventory_item.ground_collision_shape
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ... (variabili iniziali invariate)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		print("DEBUG (PickUp): Player entrato nel raggio di: ", name)
		
		# CONTROLLA QUESTE RIGHE:
		if body.has_node("Key"):
			body.get_node("Key").show() # Deve esserci .show()
		
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt") # Deve esserci .play()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		
		# AGGIUNGI QUESTE RIGHE:
		if body.has_node("Key"):
			body.get_node("Key").hide() # Nasconde lo sprite
			
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop() # Ferma l'animazione
			
		current_player = null
		print("DEBUG (PickUp): Player uscito dal raggio.")

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		print("DEBUG (PickUp): Input 'interact' rilevato!")
		collect()

func collect() -> void:
	print("DEBUG (PickUp): Inizio funzione collect()...")
	if current_player:
		var player_inv = current_player.get_node_or_null("Inventory")
		if player_inv:
			print("DEBUG (PickUp): Inventario trovato sul player. Invio dati...")
			player_inv.add_item(inventory_item)
		else:
			print("ERRORE (PickUp): Nodo 'inventory' non trovato sul player!")
	
	# ... (pulizia prompt)
	print("DEBUG (PickUp): Rimozione oggetto dal mondo (queue_free).")
	queue_free()
