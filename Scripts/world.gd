extends Node2D

@onready var player = $player
@onready var player_spawn_point: Marker2D = $PlayerSpawnPoint

func _ready():
	if Global.player_pos != Vector2.ZERO:
		player.global_position = Global.player_pos
