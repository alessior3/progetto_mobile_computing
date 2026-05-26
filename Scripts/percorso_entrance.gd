extends Area2D

var can_trigger = false

func _ready():
	# Protezione di 1 secondo all'avvio della scena
	await get_tree().create_timer(1.0).timeout
	can_trigger = true

func _on_body_entered(body: Node2D) -> void:
	# Importante: eseguiamo la transizione SOLO se siamo nella scena "world"
	# Se world.tscn è istanziata dentro un'altra scena, non deve attivare il cambio scena.
	if get_tree().current_scene.name != "world":
		return
		
	if not can_trigger:
		return
		
	print("Area Enter rilevata entrata di: ", body.name)
	if body.name == "player" or body.has_method("set_house"):
		print("Player rilevato! Caricamento automatico di Percorso1...")
		
		# Cambia scena verso Percorso1
		if TransitionChangeManager:
			TransitionChangeManager.change_scene("res://Scenes/Percorso1.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/Percorso1.tscn")

func _on_body_exited(body: Node2D) -> void:
	pass

func enter():
	Global.play_door_open()
	pass
