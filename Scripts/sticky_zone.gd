extends Area2D

class_name StickyZone

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.has_method("set_in_slime"):
		body.set_in_slime(true)
	elif "is_in_slime" in body:
		body.is_in_slime = true

func _on_body_exited(body: Node2D):
	if body.has_method("set_in_slime"):
		body.set_in_slime(false)
	elif "is_in_slime" in body:
		body.is_in_slime = false
