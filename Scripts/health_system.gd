extends Node
class_name HealthSystem

signal died
signal damage_taken(current_health: int)

@export var max_health: int
var current_health: int

func init(health: int):
	max_health = health
	current_health = health
	
# 1. Abbiamo cambiato il nome in "take_damage" per farlo combaciare con Player e Bestia
func take_damage(damage: int):
	current_health = current_health - damage
	
	# 2. Ora inviamo la VITA RIMANENTE alla barra, non il danno!
	damage_taken.emit(current_health)
	
	if current_health <= 0:
		died.emit()
