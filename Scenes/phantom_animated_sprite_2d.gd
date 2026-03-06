extends AnimatedSprite2D

class_name EnemyAnimatedSprite2D

const MOVEMENT_TO_IDLE = {
	"back_walk": "back_idle",
	"front_walk": "front_idle",
	"right_walk": "right_idle",
	"left_walk": "left_idle"
}

var last_direction: Vector2 = Vector2.ZERO


func play_movement_animation(direction: Vector2):
	if direction.distance_squared_to(last_direction) < 0.01:
		return
		
	last_direction = direction
	
	
	if direction.x > 0 and abs(direction.x) > abs(direction.y):
		play("right_walk")
		return
	elif direction.x < 0 and abs(direction.x) > abs(direction.y):
		play("left walk")
		return
	
func play_idle_animation():
		if MOVEMENT_TO_IDLE.keys().has(animation):
			play(MOVEMENT_TO_IDLE[animation])
			
