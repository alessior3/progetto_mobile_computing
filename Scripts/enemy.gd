extends Node2D # La pianta è ferma, Node2D è sufficiente.

# Manteniamo il nome della classe che hai già digitato.
class_name ExplosivePlant

# --- VARIABILI ESPORTATE (Configurabili dall'Inspector) ---
@export var max_health: int = 30
@export var damage_to_player: int = 10 # Danno che potrebbe fare al contatto?

# Questa è la variabile CRUCIALE per rilasciare la bomba.
# Qui devi trascinare dall'Inspector il file .tscn della tua Bomba.
@export var bomb_scene: PackedScene 

# --- RIFERIMENTI AI NODI INTERNI ---
# Usiamo i nomi esatti che vedo nel pannello Scene di image_8.png.
@onready var health_system: HealthSystem = $HealthSystem
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D # Lo Sprite animato generico
@onready var progress_bar: ProgressBar = $ProgressBar

# Otteniamo i riferimenti alle collisioni per disabilitarle alla morte.
# Basandomi sulla gerarchia di image_8.png:
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_collision: CollisionShape2D = $Area2D/CollisionShape2D

# Dichiarazione della variabile tipizzata per l'animated sprite custom (verrà settata in _ready)
var plant_anim: PlantAnimatedSprite

func _ready():
	# 1. Configurazione Iniziale Salute
	health_system.init(max_health)
	
	# Configurazione Progress Bar
	progress_bar.max_value = max_health
	progress_bar.value = max_health
	
	# 2. Otteniamo il riferimento tipizzato per usare le nostre funzioni helper custom
	plant_anim = anim as PlantAnimatedSprite
	
	# 3. Connettiamo il segnale di morte del HealthSystem
	health_system.died.connect(_on_plant_died)
	
	# 4. Facciamo partire l'animazione Idle iniziale tramite helper custom
	plant_anim.play_idle()

# Questa funzione gestisce la sequenza di morte:
# ferma l'idle -> fa partire l'animazione di morte -> aspetta che finisca.
func _on_plant_died():
	# A. Disabilitiamo le collisioni in modo sicuro (deferred) affinché non interagisca più.
	collision_shape.set_deferred("disabled", true)
	area_collision.set_deferred("disabled", true)
	
	# B. Nascondiamo la barra della salute (o la lasciamo scendere a zero prima).
	progress_bar.visible = false
	
	# C. Facciamo partire l'animazione di morte tramite helper custom.
	# Ora dobbiamo attendere che questa animazione finisca prima di spawnare la bomba.
	plant_anim.play_death()

# --- GESTIONE DEI SEGNALI DALL'EDITOR (Cruciale collegarli!) ---

# Devi andare nel pannello 'Node' del tuo AnimatedSprite2D e collegare il segnale
# 'animation_finished()' a QUESTA funzione nello script.
func _on_animated_sprite_2d_animation_finished():
	# Controlliamo che l'animazione finita sia proprio 'death_animation'.
	if anim.animation == "death_animation":
		spawn_bomb_and_destroy()

# Questa funzione esegue l'azione speciale della pianta.
func spawn_bomb_and_destroy():
	# Verifichiamo di aver assegnato la scena della bomba nell'Inspector.
	if bomb_scene != null:
		# 1. Istanziamo la copia della bomba.
		var bomb_instance = bomb_scene.instantiate()
		
		# 2. La posizioniamo esattamente dove si trova la pianta.
		bomb_instance.global_position = global_position
		
		# 3. La aggiungiamo al mondo di gioco (il nodo padre della pianta, es. il mondo dungeon).
		get_parent().add_child(bomb_instance)
		
	else:
		printerr("Attenzione: Non hai assegnato la scena 'bomb_scene' nell'Inspector di ExplosivePlant!")

	# 4. Infine, cancelliamo la pianta dal mondo.
	queue_free()

# Helper function per subire danno, da chiamare esternamente (es. dal giocatore).
func apply_damage(damage_amount: int):
	health_system.apply_damage(damage_amount)
	progress_bar.value = health_system.current_health
	
	# Se vogliamo un feedback visivo di colpo subito (se l'animazione esiste)
	if health_system.current_health > 0:
		# plant_anim.play_hit() # Abilita se hai fatto la helper play_hit e l'animazione
		pass
