extends Area2D

class_name StickyZone

@export_category("Slime Effects")
@export_range(0.1, 1.0) var slowing_multiplier: float = 0.4
@export var disable_attack: bool = true

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D):
	if body.has_method("set_slime_effects"):
		body.set_slime_effects(true, slowing_multiplier, disable_attack)
	elif body.has_method("set_in_slime"):
		body.set_in_slime(true)
	elif "is_in_slime" in body:
		body.is_in_slime = true

func _on_body_exited(body: Node2D):
	if body.has_method("set_slime_effects"):
		body.set_slime_effects(false, 1.0, false)
	elif body.has_method("set_in_slime"):
		body.set_in_slime(false)
	elif "is_in_slime" in body:
		body.is_in_slime = false
