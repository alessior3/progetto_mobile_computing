extends StaticBody2D
class_name ArenaDoor
@export var start_closed: bool = false
@export var requires_gems: bool = false
@onready var anim = $AnimationPlayer
@onready var collision = $CollisionShape2D

var is_closed = false
var opened_with_gems = false

func _ready():
	if not has_node("DoorOpen"):
		var door_open_sound = AudioStreamPlayer.new()
		door_open_sound.name = "DoorOpen"
		door_open_sound.stream = preload("res://Sounds/apertura_porta.mp3")
		add_child(door_open_sound)
	if not has_node("DoorClose"):
		var door_close_sound = AudioStreamPlayer.new()
		door_close_sound.name = "DoorClose"
		door_close_sound.stream = preload("res://Sounds/chiusura_porta.mp3")
		add_child(door_close_sound)
	
	if (start_closed or requires_gems):
		is_closed = true
		if anim:
			anim.play("close")
			anim.seek(anim.current_animation_length, true)
		if collision:
			collision.disabled = false
		z_index = 0

func _process(_delta):
	if requires_gems and is_closed and not opened_with_gems:
		if Global.get("pc_boss_1_on") and Global.get("pc_boss_2_on") and Global.get("pc_boss_3_on"):
			opened_with_gems = true
			open_door()

func open_door():
	$DoorOpen.play()
	if not is_node_ready():
		await ready
	
	print("DEBUG: open_door() chiamato su ", name)
	if anim:
		anim.play("open")
	collision.set_deferred("disabled", true)
	is_closed = false
	
	# Passa in secondo piano quando è aperto
	z_index = -1
	print("DEBUG: Cancello ", name, " APERTO. Z-Index impostato a: ", z_index, " (Disabilitato Y-Sort con il player)")

func close_door():
	$DoorClose.play()
	if not is_node_ready():
		await ready
		
	print("DEBUG: close_door() chiamato su ", name)
	if anim:
		anim.play("close")
	collision.set_deferred("disabled", false)
	is_closed = true
	
	# Torna allo stesso livello del player quando è chiuso
	z_index = 0
	print("DEBUG: Cancello ", name, " CHIUSO. Z-Index impostato a: ", z_index, " (Riattivato Y-Sort con il player)")
