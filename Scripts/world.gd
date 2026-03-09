extends Node2D

@onready var player = $player
@onready var player_spawn_point: Marker2D = $PlayerSpawnPoint

func _ready():

	if SaveManager.is_loading_game:
		return

	if Global.player_pos != Vector2.ZERO:
		player.global_position = Global.player_pos
	else:
		player.global_position = player_spawn_point.global_position
