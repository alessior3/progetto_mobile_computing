extends Area2D

var can_trigger = false

func _ready():
	# Disabilita l'uscita per 1 secondo all'inizio per evitare teletrasporti accidentali
	await get_tree().create_timer(1.0).timeout
	can_trigger = true

func _on_body_entered(body: Node2D) -> void:
	# Eseguiamo il ritorno al world solo se siamo effettivamente in Percorso1
	if get_tree().current_scene.name != "Percorso1":
		return
		
	if not can_trigger:
		return
		
	print("Area Exit rilevata entrata di: ", body.name)
	if body.name == "player" or body.has_method("set_house"):
		print("Player rilevato! Ritorno automatico in world...")
		Global.from_percorso = true
		
		# Torna al mondo immediatamente
		if TransitionChangeManager:
			TransitionChangeManager.change_scene("res://Scenes/world.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_body_exited(body: Node2D) -> void:
	pass

func enter():
	pass
