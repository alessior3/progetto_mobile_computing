extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.player_pos != Vector2.ZERO:
		global_position = Global.player_pos
