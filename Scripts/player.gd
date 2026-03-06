extends CharacterBody2D

const speed = 100
var current_dir = "none"

var house = null:
	set = set_house

func set_house(new_house):
	if new_house != null:
		$Key.show()
		$KeyPrompt.play("KeyPrompt")
	else:
		$Key.hide()
		$KeyPrompt.stop()
	house = new_house

# ECCO LA FUNZIONE FUSA E CORRETTA:
func _ready():
	$AnimatedSprite2D.play("idle_front")
	set_house(null)
	
	# La parte del nome fusa dentro l'unico _ready()
	if has_node("Label"):
		$Label.text = Global.current_username
		
	# --- NUOVO: CARICAMENTO POSIZIONE ---
	# Se la posizione in memoria non è vuota (0,0), sposta l'omino lì!
	if Global.player_pos != Vector2.ZERO:
		global_position = Global.player_pos


func _unhandled_input(event):
	# Codice originale per entrare in casa
	if event is InputEventKey and event.is_action_pressed("interact") and house != null:
		Global.player_pos = global_position
		house.enter()
		
	# --- NUOVO: SALVATAGGIO CON TASTO K ---
	# Se premi il tasto K sulla tastiera, salva la posizione e il gioco!
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		Global.player_pos = global_position
		Global.save_game()


func _physics_process(delta):
	player_movement(delta)

func player_movement(delta):
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_anim(1)
		velocity.y = speed
		velocity.x = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_anim(1)
		velocity.y = -speed
		velocity.x = 0
	else:
		play_anim(0)
		velocity = Vector2.ZERO

	move_and_slide()

func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D

	if dir == "right":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_side")
		else:
			anim.play("idle_side")
	if dir == "left":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_side")
		else:
			anim.play("idle_side")
	if dir == "down":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_front")
		else:
			anim.play("idle_front")
	if dir == "up":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_back")
		else:
			anim.play("idle_back")
