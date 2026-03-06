extends CharacterBody2D

# Diamo un nome alla classe, proprio come nel tutorial!
class_name ExplosivePlant

# --- VARIABILI ESPORTATE (Le potrai modificare dall'Inspector!) ---
@export var max_health: int = 30
@export var damage_to_player: int = 10
@export var bomb_scene: PackedScene # Questa è la nostra versione di "item_to_drop"

# --- RIFERIMENTI AI NODI ---
@onready var health_system: HealthSystem = $HealthSystem
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# 1. Inizializziamo la vita usando la variabile esportata invece di un numero fisso
	health_system.init(max_health)
	
	# 2. Colleghiamo i segnali dell'HealthSystem
	health_system.died.connect(_on_health_system_died)
	health_system.damage_taken.connect(_on_health_system_damage_taken)

# Questa funzione verrà chiamata quando il giocatore attacca la pianta
func take_damage(amount: int) -> void:
	health_system.apply_damage(amount)

# --- REAZIONI AI SEGNALI ---

func _on_health_system_damage_taken(damage_amount: int) -> void:
	print("La pianta ha subito ", damage_amount, " danni! Salute: ", health_system.current_health)

func _on_health_system_died() -> void:
	esplodi_e_rilascia_bomba()

# --- LOGICA DELL'ESPLOSIONE ---

func esplodi_e_rilascia_bomba() -> void:
	print("BOOM! La pianta esplode!")
	
	# Creiamo la bomba se è stata inserita nell'Inspector
	if bomb_scene != null:
		var bomba = bomb_scene.instantiate()
		bomba.global_position = global_position
		get_parent().call_deferred("add_child", bomba)
	else:
		print("Attenzione: Manca la scena della bomba nell'Inspector!")
		
	# Distruggiamo la pianta
	queue_free()
