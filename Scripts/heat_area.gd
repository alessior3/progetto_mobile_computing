extends Area2D

@export var damage_per_second: int = 5
@export var heat_message: String = "ATTENZIONE: Surriscaldamento rilevato! Temperatura oltre i limiti."

var player_inside: Player = null
var damage_timer: Timer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	damage_timer = Timer.new()
	damage_timer.wait_time = 1.0
	damage_timer.timeout.connect(_on_damage_tick)
	add_child(damage_timer)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_inside = body
		damage_timer.start()
		print(heat_message)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_inside = null
		damage_timer.stop()

func _on_damage_tick():
	if player_inside and player_inside.health_system:
		player_inside.health_system.take_damage(damage_per_second)
		# Feedback visivo del calore (opzionale)
		player_inside.modulate = Color(1.0, 0.5, 0.5) # Leggermente rosso
		await get_tree().create_timer(0.2).timeout
		if player_inside: player_inside.modulate = Color(1, 1, 1)
