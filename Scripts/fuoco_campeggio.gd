extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var interaction_area = $areaAccendiFuoco

var player_in_area = false

func _ready():
	# L'animazione parte spenta per default
	animated_sprite.play("FuocoSpento_an")
	
	# Connettiamo i segnali dell'area di interazione
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_area = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false

func _input(event):
	# Se il player è nell'area e preme il tasto di interazione
	if player_in_area and event.is_action_pressed("interact"):
		accendi_fuoco()

func accendi_fuoco():
	animated_sprite.play("FuocoAcceso_an")
	print("Fuoco acceso!")
