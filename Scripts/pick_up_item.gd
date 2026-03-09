@tool # Permette l'esecuzione del codice nell'editor
extends Area2D
class_name PickUpItem

# Setter: ogni volta che cambi l'item nell'Inspector, esegue _update_visuals()
@export var inventory_item : InventoryItem :
	set(value):
		inventory_item = value
		_update_visuals()

@export var amount: int=1

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var player_in_range : bool = false
var current_player : CharacterBody2D = null

func _ready() -> void:
	# Colleghiamo i segnali solo se non siamo nell'editor (evita ghosting)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	
	_update_visuals()

# Funzione centrale per la grafica (funziona sia in gioco che in editor)
func _update_visuals() -> void:
	# Sicurezza: aspetta che i nodi siano pronti prima di usarli
	if not is_inside_tree(): return
	
	# In modalità @tool, le variabili @onready potrebbero essere nulle al primo caricamento
	var s2d = sprite_2d if sprite_2d else get_node_or_null("Sprite2D")
	var c2d = collision_shape_2d if collision_shape_2d else get_node_or_null("CollisionShape2D")
	
	if inventory_item:
		if s2d: s2d.texture = inventory_item.texture
		if c2d: c2d.shape = inventory_item.ground_collision_shape
	else:
		# Se l'item è vuoto nell'inspector, puliamo lo sprite
		if s2d: s2d.texture = null

# --- LOGICA DI GIOCO (Ignorata dall'editor grazie a Engine.is_editor_hint) ---

func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint(): return # Sicurezza extra
	
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		print("DEBUG (PickUp): Player nel raggio di: ", inventory_item.name if inventory_item else name)
		
		# Gestione prompt interazione sul player
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint(): return
	
	if body.is_in_group("player"):
		player_in_range = false
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").stop()
		current_player = null
		print("DEBUG (PickUp): Player uscito.")

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	
	if player_in_range and event.is_action_pressed("interact"):
		collect()

func collect() -> void:
	if current_player and inventory_item:
		var player_inv = current_player.get_node_or_null("Inventory")
		if player_inv:
			# MODIFICA QUESTA RIGA: passiamo anche la quantità 'amount'
			player_inv.add_item(inventory_item, amount)
			print("DEBUG (PickUp): Raccolti ", amount, "x ", inventory_item.name)
		else:
			print("ERRORE: Inventario non trovato!")
	
	queue_free()
