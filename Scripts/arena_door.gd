extends StaticBody2D
class_name ArenaDoor

@onready var anim = $AnimationPlayer
@onready var collision = $CollisionShape2D

var is_closed = false

func _ready():
	# Starts open
	pass # We let the ArenaManager decide when to open/close during its _ready

func open_door():
	if not is_node_ready():
		await ready
	
	print("DEBUG: open_door() chiamato su ", name)
	if anim:
		anim.play("open")
	collision.set_deferred("disabled", true)
	is_closed = false

func close_door():
	if not is_node_ready():
		await ready
		
	print("DEBUG: close_door() chiamato su ", name)
	if anim:
		anim.play("close")
	collision.set_deferred("disabled", false)
	is_closed = true
