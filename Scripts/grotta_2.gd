extends Node2D

@onready var door_sprite = $DoorWay/Sprite2D

func _ready() -> void:
	pass

func _on_door_way_body_entered(body: Node2D) -> void:
	if body.name == "player":
		body.house = self

func _on_door_way_body_exited(body: Node2D) -> void:
	if body.name == "player":
		if body.house == self:
			body.house = null

func enter():
	# Animazione della porta:
	# Rimuove l'immagine della porta chiusa per mostrare la grotta sotto
	if door_sprite:
		door_sprite.hide()
	
	# Attende un attimo per dare un effetto visivo di apertura
	await get_tree().create_timer(0.2).timeout
	
	# Per ora non scrivo nulla sull'entrata/uscita dalla grotta come richiesto
