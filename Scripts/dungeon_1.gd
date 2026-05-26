extends Node2D

@onready var player = find_child("player", true, false)
@onready var spawn_point = find_child("Spawn", true, false)

func _ready():
	# Add dungeon background music if not present
	if not has_node("DungeonSound"):
		var dungeon_sound = AudioStreamPlayer.new()
		dungeon_sound.name = "DungeonSound"
		dungeon_sound.stream = preload("res://Sounds/dungeon_sound.wav")
		dungeon_sound.autoplay = true
		dungeon_sound.volume_db = -25.0
		add_child(dungeon_sound)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if player:
		var target_pos = player.global_position
		
		if Global.from_grotta2_to_dungeon2:
			if spawn_point:
				target_pos = spawn_point.global_position
				print("DEBUG: Spostamento su Spawn (global_pos: ", target_pos, ")")
			Global.from_grotta2_to_dungeon2 = false
		
		# Force position for a few frames to avoid physics issues
		for i in range(10):
			player.global_position = target_pos
			await get_tree().physics_frame
		
		# Reset the camera
		var camera = player.find_child("Camera2D", true, false)
		if not camera:
			camera = player.find_child("playerCamera", true, false)
		if camera:
			camera.reset_smoothing()
			camera.force_update_scroll()
