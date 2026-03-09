extends AnimatedSprite2D

# Diamo un nome unico a questo script
class_name PhantomAnimatedSprite2D

# Questa variabile ricorda da che parte stiamo guardando (di base a destra)
var is_facing_right: bool = true

func play_movement_animation(direction: Vector2):
	if direction.x < 0:
		is_facing_right = false
		play("run_animation_left")
	elif direction.x > 0:
		is_facing_right = true
		play("run_animation_right")
	else:
		# Se va dritto su o giù, continuiamo a guardare nell'ultima direzione
		if is_facing_right:
			play("run_animation_right")
		else:
			play("run_animation_left")

func play_idle_animation():
	if is_facing_right:
		play("idle_animation_right")
	else:
		play("idle_animation_left")

func play_hit_animation():
	if is_facing_right:
		play("hit_right_animation")
	else:
		play("hit_left_animation")

# NUOVA FUNZIONE: Decide come morire in base a dove guardava
func play_death_animation():
	if is_facing_right:
		play("death_animation_right")
	else:
		play("death_animation_left")
