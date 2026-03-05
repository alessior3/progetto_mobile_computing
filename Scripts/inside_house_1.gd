extends Node2D

var outside = "res://Scenes/world.tscn"

# --- 1. GESTIONE ENTRATA (Il pezzo nuovo) ---
func _ready():
	# Appena entriamo in casa, cerchiamo il player e il punto di spawn
	if has_node("player") and has_node("SpawnPoint"):
		# Spostiamo l'omino esattamente sopra il Marker2D che hai creato
		$player.global_position = $SpawnPoint.global_position
		
		# Opzionale: diciamo alla telecamera di resettarsi subito sulla nuova posizione
		if $player.has_node("Camera2D"):
			$player.get_node("Camera2D").reset_smoothing()

# --- 2. GESTIONE USCITA (Il tuo codice originale) ---
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "player":
		# Prima di uscire, resettiamo la posizione globale a zero 
		# così quando rientri nel mondo non "nasci" dentro la casa
		Global.player_pos = Vector2.ZERO
		call_deferred("change_scene")

func change_scene():
	get_tree().change_scene_to_file(outside)
