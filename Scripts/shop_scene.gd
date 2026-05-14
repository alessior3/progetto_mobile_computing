extends Node

const PLAYE_SCENE = preload("res://Scenes/player.tscn")
@onready var player_spawn_place_marker: Marker2D = $PlayerSpawnPlace

# Creiamo una variabile per "ricordarci" del giocatore
var spawned_player = null 

func _ready() -> void:
	TransitionChangeManager.transition_done.connect(on_transition_done)
	
	# Cerchiamo se c'è già un player (magari messo a mano nell'editor per la camera)
	spawned_player = get_tree().get_first_node_in_group("player")
	
	if spawned_player == null:
		# Se non c'è, lo creiamo noi dinamicamente
		spawned_player = PLAYE_SCENE.instantiate()
		self.add_child(spawned_player)
		if player_spawn_place_marker:
			spawned_player.position = player_spawn_place_marker.position
	else:
		# Se c'è già, lo posizioniamo semplicemente al punto di spawn
		if player_spawn_place_marker:
			spawned_player.position = player_spawn_place_marker.position
	
func on_transition_done():
	# Invece di usare $Player, usiamo la nostra variabile sicura!
	if spawned_player != null:
		spawned_player.set_physics_process(true)

func _on_exit_area_body_entered(_body: Node2D) -> void:
	if Global.last_world_scene != "":
		TransitionChangeManager.change_scene(Global.last_world_scene)
	else:
		TransitionChangeManager.change_scene("res://Scenes/world.tscn")
