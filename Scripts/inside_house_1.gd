extends Node2D

var outside = "res://Scenes/world.tscn"

# --- 1. GESTIONE ENTRATA ---
func _ready():
	# --- SUONO: LA PORTA SI CHIUDE ALLE TUE SPALLE ---
	if has_node("DoorClose"):
		$DoorClose.play()
	# -------------------------------------------------

	# Appena entriamo in casa, cerchiamo il player e il punto di spawn
	if has_node("player") and has_node("SpawnPoint"):
		# SICUREZZA: Sblocchiamo il player se fosse rimasto bloccato dalla transizione
		if "can_move" in $player:
			$player.can_move = true
			
		# Spostiamo l'omino esattamente sopra il Marker2D che hai creato
		$player.global_position = $SpawnPoint.global_position
		
		# Opzionale: diciamo alla telecamera di resettarsi subito sulla nuova posizione
		if $player.has_node("Camera2D"):
			$player.get_node("Camera2D").reset_smoothing()

# --- 2. GESTIONE USCITA ---
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name == "player" or body.is_in_group("player"): # Aggiunto il controllo gruppo per sicurezza extra
		
		# --- SUONO: APRI LA PORTA PER USCIRE ---
		if has_node("DoorOpen"):
			$DoorOpen.play()
		# ---------------------------------------
		
		# Opzionale: blocchiamo il player un attimo così non si muove durante il caricamento
		if "can_move" in body:
			body.can_move = false
		
		# ASPETTIAMO UN ATTIMO: diamo il tempo al suono di sentirsi prima di cambiare scena!
		await get_tree().create_timer(0.3).timeout
		
		# Non azzeriamo la posizione qui: vogliamo che il mondo
		# riposizioni il player al punto da cui è entrato.
		call_deferred("change_scene")

func change_scene():
	var target_scene = outside
	if Global.last_world_scene != "":
		target_scene = Global.last_world_scene
		
	if Global.from_grotta_to_percorso or Global.from_house3_to_percorso:
		target_scene = "res://Scenes/Percorso1.tscn"
	
	if TransitionChangeManager:
		TransitionChangeManager.change_scene(target_scene)
	else:
		get_tree().change_scene_to_file(target_scene)
