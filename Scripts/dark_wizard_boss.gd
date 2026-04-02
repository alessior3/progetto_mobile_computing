extends Node2D
class_name DarkWizardBoss

# --- VARIABILI DELLA SALUTE ---
@export var max_hp: int = 5
var hp: int = 5
var damage_count: int = 0

# --- VARIABILI DEL TELETRASPORTO ---
var current_position: int = 0
var positions: Array[Vector2] = []

# --- COLLEGAMENTO AI NODI DELLA SCENA ---
@onready var boss_node = $BossNode
@onready var anim_player = $BossNode/AnimationPlayer
@onready var anim_player_damaged = $BossNode/AnimationPlayer_Damaged
@onready var hurt_box = $BossNode/Hurtbox
@onready var hit_box = $BossNode/Hitbox
@onready var position_targets = $PositionTargets

func _ready():
	hp = max_hp
	
	# Trova le coordinate dei 4 punti e li nasconde
	for c in position_targets.get_children():
		positions.append(c.global_position)
	position_targets.visible = false
	
	# Connette la tua Hurtbox. (Se la tua usa un nome diverso per il segnale, lo sistemeremo)
	if hurt_box.has_signal("damaged"):
		hurt_box.damaged.connect(_on_damage_taken)
	elif hurt_box.has_signal("area_entered"):
		hurt_box.area_entered.connect(_on_damage_taken)
		
	# Inizia la battaglia teletrasportandosi nel punto Top (0)
	teleport(0)

func _on_damage_taken(attack_hitbox):
	# Se sta già lampeggiando, è invincibile (i-frames)
	if anim_player_damaged.current_animation == "damaged":
		return
		
	# Calcola il danno (adattato per evitare crash col tuo sistema)
	var damage_amount = 1
	if "damage" in attack_hitbox:
		damage_amount = attack_hitbox.damage
		
	hp -= damage_amount
	damage_count += 1
	
	# Fa lampeggiare il boss
	anim_player_damaged.play("damaged")
	
	if hp <= 0:
		defeat()

func enable_hitboxes(is_active: bool):
	hit_box.set_deferred("monitorable", is_active)
	hurt_box.set_deferred("monitoring", is_active)

# --- MACCHINA A STATI (Il "Cervello" del Boss) ---

func teleport(location: int):
	damage_count = 0
	enable_hitboxes(false) # Disattiva le collisioni mentre svanisce
	
	anim_player.play("disappear")
	await anim_player.animation_finished
	
	await get_tree().create_timer(0.5).timeout # Piccola pausa in cui è invisibile
	
	# Muove il boss nella nuova posizione
	boss_node.global_position = positions[location]
	current_position = location
	
	# Specchia lo sprite se appare a Destra (Posizione 1)
	if current_position == 1:
		boss_node.scale = Vector2(-1, 1)
	else:
		boss_node.scale = Vector2(1, 1)
		
	anim_player.play("appear")
	await anim_player.animation_finished
	
	idle() # Passa alla fase successiva

func idle():
	enable_hitboxes(true) # Riattiva le collisioni
	
	# Ha il 50% di probabilità di stare fermo a fluttuare prima di attaccare
	if randf() > 0.5:
		anim_player.play("idle")
		await anim_player.animation_finished
		if hp <= 0: return # Se è morto mentre fluttuava, ferma tutto
		
	# Lancia l'attacco
	if damage_count < 1: # Attacca solo se non lo hai appena colpito
		anim_player.play("cast_spell")
		
		# [QUI IN FUTURO AGGIUNGEREMO I CODICI PER GENERARE I LASER/SFERE]
		
		await anim_player.animation_finished
		if hp <= 0: return
		
	# Finito l'attacco, sceglie un nuovo punto a caso in cui teletrasportarsi
	var next_pos: int = current_position
	while next_pos == current_position:
		next_pos = randi() % 4 # Sceglie a caso tra 0, 1, 2, 3
		
	teleport(next_pos) # Ricomincia il ciclo!

func defeat():
	enable_hitboxes(false)
	
	# Se per caso non abbiamo creato un'animazione "destroy", lo fa svanire in automatico
	if anim_player.has_animation("destroy"):
		anim_player.play("destroy")
		await anim_player.animation_finished
	else:
		var tween = create_tween()
		tween.tween_property(boss_node, "modulate:a", 0.0, 1.0)
		await tween.finished
		
	queue_free() # Elimina il boss dalla scena
