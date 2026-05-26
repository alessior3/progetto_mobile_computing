extends StaticBody2D

var is_open = false

func _ready():
	if has_node("AnimationPlayer"):
		var anim = $AnimationPlayer
		if anim.has_animation("close"):
			anim.play("close")
			anim.seek(anim.current_animation_length, true)

func _process(_delta):
	if is_open: return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) < 60:
		if _player_has_gems(player):
			open_door()

func _player_has_gems(player) -> bool:
	if not player.has_node("Inventory"):
		return false
	var inv = player.get_node("Inventory")
	var has_g = false
	var has_p = false
	var has_r = false
	for item in inv.items:
		if item != null:
			if item.item_id == "gem_green": has_g = true
			if item.item_id == "gem_purple": has_p = true
			if item.item_id == "gem_red": has_r = true
	return has_g and has_p and has_r

func open_door():
	is_open = true
	if has_node("DoorOpen"):
		$DoorOpen.play()
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("open")
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	z_index = -1
