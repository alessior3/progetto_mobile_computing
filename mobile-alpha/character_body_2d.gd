extends CharacterBody2D
const SPEED = 300.0

func _physics_process(delta):
	var movement = Vector2()
	movement.x=Input.get_axis("ui_left", "ui_right")
	movement.y=Input.get_axis("ui_up", "ui_down")
	movement=movement.normalized()
	
	velocity=movement*SPEED
	move_and_slide()
