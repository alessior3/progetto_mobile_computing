extends Node2D

var outside = "res://Scenes/world.tscn"

func _ready():
	if has_node("player") and has_node("SpawnPoint"):
		$player.can_move = true
		$player.global_position = $SpawnPoint.global_position
		if $player.has_node("Camera2D"):
			$player.get_node("Camera2D").reset_smoothing()
	
	if has_node("DoorClose"):
		$DoorClose.play()

func _on_exit_area_body_entered(body: Node2D) -> void:
	if body is Player:
		if has_node("DoorOpen"):
			$DoorOpen.play()
		
		body.can_move = false
		await get_tree().create_timer(0.3).timeout
		
		if TransitionChangeManager:
			TransitionChangeManager.change_scene(outside)
		else:
			get_tree().change_scene_to_file(outside)
