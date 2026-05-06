extends Node2D

@onready var player = $"../player"

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_door_way_body_entered(body: Node2D) -> void:
	body.house = self

func _on_door_way_body_exited(body: Node2D) -> void:
	if body.house == self:
		body.house = null

func enter():
	Global.player_pos = player.global_position
	# Cambiamo scena verso l'interno della casa 2
	TransitionChangeManager.change_scene("res://Scenes/inside_house2.tscn")
