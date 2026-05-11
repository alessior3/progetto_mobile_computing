extends Area2D

@export var target_scene: String = ""
@export var transition_flag: String = ""

var can_trigger = false

func _ready():
	# Protezione di 1 secondo all'avvio della scena
	await get_tree().create_timer(1.0).timeout
	can_trigger = true

func _on_body_entered(body: Node2D) -> void:
	if not can_trigger:
		return
		
	if body.name == "player":
		print("Player entering transition area to: ", target_scene)
		if transition_flag != "":
			Global.set(transition_flag, true)
		
		if TransitionChangeManager:
			TransitionChangeManager.change_scene(target_scene)
		else:
			get_tree().change_scene_to_file(target_scene)
