extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# L'NPC deve riprodurre l'animazione di idle
	if animated_sprite_2d:
		animated_sprite_2d.play("idle_an")

func _on_interaction_area_body_entered(_body: Node2D) -> void:
	# Placeholder per interazione futura (segnale già presente nella scena)
	pass

func _on_interaction_area_body_exited(_body: Node2D) -> void:
	# Placeholder per interazione futura (segnale già presente nella scena)
	pass
