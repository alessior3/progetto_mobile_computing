extends Node2D

@onready var player = $player

func _ready():
	if Global.player_pos != Vector2.ZERO:
		player.global_position = Global.player_pos
