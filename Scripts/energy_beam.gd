extends Area2D

@onready var animation_player = $AnimationPlayer

func _ready():
	# Si assicura che parta disattivato
	monitoring = false
	modulate.a = 0

# Questa funzione verrà chiamata dal Boss!
func attack():
	animation_player.play("attack")
