extends Area2D

var ignore_first_trigger = true

func _ready():
	await get_tree().process_frame
	ignore_first_trigger = false

func _on_body_entered(body: Node2D) -> void:
	if ignore_first_trigger:
		return

	if body.name == "player" or body.name == "Player":
		Global.player_pos = body.global_position
		TransitionChangeManager.change_scene("res://Scenes/shop_scene.tscn")
