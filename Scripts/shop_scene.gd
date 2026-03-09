extends Node

const PLAYE_SCENE = preload("res://Scenes/player.tscn")
@onready var player_spawn_place_marker: Marker2D = $PlayerSpawnPlace

# Creiamo una variabile per "ricordarci" del giocatore
var spawned_player = null 

func _ready() -> void:
	TransitionChangeManager.transition_done.connect(on_transition_done)
	
	# Salviamo il giocatore appena creato in questa memoria
	spawned_player = PLAYE_SCENE.instantiate()
	self.add_child(spawned_player)
	spawned_player.position = player_spawn_place_marker.position
	
func on_transition_done():
	# Invece di usare $Player, usiamo la nostra variabile sicura!
	if spawned_player != null:
		spawned_player.set_physics_process(true)

func _on_exit_area_body_entered(_body: Node2D) -> void:
	TransitionChangeManager.change_scene("res://Scenes/world.tscn")
