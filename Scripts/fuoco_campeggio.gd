extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var interaction_area = $areaAccendiFuoco

var player_in_area = false
var is_lit = false
var current_player = null

func _ready():
	# L'animazione parte spenta per default
	animated_sprite.play("FuocoSpento_an")
	
	# Connettiamo i segnali dell'area di interazione
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true
		current_player = body
		if not is_lit:
			if body.has_node("Key"):
				body.get_node("Key").show()
			if body.has_node("KeyPrompt"):
				body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false
		current_player = null
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

func _input(event):
	# Se il player è nell'area, il falò è spento e preme il tasto di interazione
	if player_in_area and not is_lit and event.is_action_pressed("interact"):
		accendi_fuoco()

func accendi_fuoco():
	is_lit = true
	animated_sprite.play("FuocoAcceso_an")
	print("Fuoco acceso!")
	
	# Nascondiamo subito il prompt dell'interazione dato che il fuoco è acceso
	if current_player:
		if current_player.has_node("Key"):
			current_player.get_node("Key").hide()
		if current_player.has_node("KeyPrompt"):
			current_player.get_node("KeyPrompt").stop()
