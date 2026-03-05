extends Node2D

@export var inside_scene: PackedScene

# 1. ECCO LA SOLUZIONE AL CRASH: Diciamo allo script chi è e dove si trova il "player"
@onready var player = $"../player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_door_way_body_entered(body: Node2D) -> void:
	body.house = self

func _on_door_way_body_exited(body: Node2D) -> void:
	# 2. BONUS FIX: Qui c'era scritto "if body.house == body", 
	# ma per avere senso logico deve essere "self" (cioè questa casa stessa)
	if body.house == self:
		body.house = null

func enter():
	# Ora lo script sa chi è "player" e questa riga funzionerà alla perfezione!
	Global.player_pos = player.global_position
	get_tree().change_scene_to_packed(inside_scene)
