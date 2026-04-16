extends Node2D
class_name DarkWizardBoss

const EXPLOSION_SCENE = preload("res://Scenes/energy_explosion.tscn")

# --- VARIABILI DELLA SALUTE ---
@export var max_hp: int = 5
var hp: int = 5
var damage_count: int = 0

# --- VARIABILI DEL TELETRASPORTO E ATTACCHI ---
var current_position: int = 0
var positions: Array[Vector2] = []
var beam_attacks: Array = [] # Lista che conterrà i tuoi laser

# --- COLLEGAMENTO AI NODI DELLA SCENA ---
@onready var boss_node = $BossNode
@onready var anim_player = $BossNode/AnimationPlayer
@onready var anim_player_damaged = $BossNode/AnimationPlayer_Damaged
@onready var hurt_box = $BossNode/Hurtbox
@onready var hit_box = $BossNode/Hitbox
@onready var position_targets = $PositionTargets
@onready var boss_health_bar = $CanvasLayer/BossHealthBar # Collegamento alla UI

func _ready():
	hp = max_hp
	
	# 1. Imposta la barra della vita
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = hp
	boss_health_bar.visible = false # Resta nascosta finché non inizia la lotta
	
	# 2. Trova le coordinate dei 4 punti e li nasconde
	for c in position_targets.get_children():
		positions.append(c.global_position)
	position_targets.visible = false
	
	# 3. Raccoglie tutti i laser che hai messo in BeamAttacks
	var beam_attacks_node = $BeamAttacks
	if beam_attacks_node:
		for b in beam_attacks_node.get_children():
			beam_attacks.append(b)
	
	# 4. Connette la tua Hurtbox
	if hurt_box.has_signal("damaged"):
		hurt_box.damaged.connect(_on_damage_taken)
	elif hurt_box.has_signal("area_entered"):
		hurt_box.area_entered.connect(_on_damage_taken)
		
	# Inizia la battaglia teletrasportandosi nel punto Top (0)
	teleport(0)

func _on_damage_taken(attack_hitbox):
	# 1. Se tocca un muro o un punto di teletrasporto (che non ha la variabile "damage"), IGNORA!
	if not "damage" in attack_hitbox:
		return
		
	# 2. Se sta già lampeggiando, ignoralo (i-frames)
	if anim_player_damaged.current_animation == "damaged":
		return
		
	# 3. Prende il danno vero
	hp -= attack_hitbox.damage
	damage_count += 1
	
	boss_health_bar.value = hp
	anim_player_damaged.play("damaged")
	
	if hp <= 0:
		defeat()

func enable_hitboxes(is_active: bool):
	hit_box.set_deferred("monitorable", is_active)
	hurt_box.set_deferred("monitoring", is_active)


# --- MACCHINA A STATI (Il "Cervello" del Boss) ---

func teleport(location: int):
	boss_node.modulate = Color.WHITE # <--- Torna colore normale
	damage_count = 0
	enable_hitboxes(false) 
	
	anim_player.play("disappear")
	await anim_player.animation_finished
	
	await get_tree().create_timer(0.5).timeout 
	
	boss_node.global_position = positions[location]
	current_position = location
	
	if current_position == 1:
		boss_node.scale = Vector2(-1, 1)
	else:
		boss_node.scale = Vector2(1, 1)
		
	anim_player.play("appear")
	await anim_player.animation_finished
	
	boss_health_bar.visible = true
	idle() 

func idle():
	boss_node.modulate = Color.WHITE # <--- Torna colore normale
	enable_hitboxes(true) 
	
	if randf() > 0.5:
		anim_player.play("idle")
		await get_tree().create_timer(1.0).timeout # Aspetta senza bloccarsi
		if hp <= 0: return 
		
	if damage_count < 1: 
		energy_beam_attack() 
		anim_player.play("cast_spell")
		await get_tree().create_timer(1.0).timeout # Aspetta senza bloccarsi
		if hp <= 0: return
		
	var next_pos: int = current_position
	while next_pos == current_position:
		next_pos = randi() % 4 
		
	teleport(next_pos)

func energy_beam_attack():
	$BeamAttacks.global_position = boss_node.global_position
	var total_beams = beam_attacks.size()
	print("Numero di laser trovati: ", total_beams)
	
	if total_beams == 0: 
		print("ERRORE: I laser sono 0! Non li hai messi dentro il nodo BeamAttacks!")
		return 
	
	var beams_to_fire: Array[int] = []
	
	beams_to_fire.append(randi_range(0, total_beams - 1))
	beams_to_fire.append(randi_range(0, total_beams - 1))
		
	if hp < (max_hp / 2):
		beams_to_fire.append(randi_range(0, total_beams - 1))
		
	print("Sto accendendo i laser!")
	for b in beams_to_fire:
		beam_attacks[b].attack()


# --- SCONFITTA ED ESPLOSIONE ---
func defeat():
	enable_hitboxes(false) 
	boss_health_bar.visible = false # Nasconde la barra della vita
	
	explosion(Vector2(0, -30)) 
	await get_tree().create_timer(0.2).timeout
	
	explosion(Vector2(20, -10)) 
	await get_tree().create_timer(0.2).timeout
	
	explosion(Vector2(-20, -10)) 
	await get_tree().create_timer(0.2).timeout
	
	explosion(Vector2(0, 10)) 
	
	var tween = create_tween()
	tween.tween_property(boss_node, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	queue_free()

func explosion(offset: Vector2 = Vector2.ZERO):
	if EXPLOSION_SCENE:
		var e = EXPLOSION_SCENE.instantiate()
		e.global_position = boss_node.global_position + offset
		get_parent().add_child.call_deferred(e)


# --- TRUCCO PER TESTARE IL DANNO SENZA GIOCATORE ---
func _input(event):
	# Se premiamo SPAZIO (o Invio) sulla tastiera
	if event.is_action_pressed("ui_accept"):
		print("SBAM! Danno finto inflitto!")
		
		# Creiamo una finta spada (un dizionario) che fa 1 di danno
		var finta_hitbox = {"damage": 1}
		
		# La mandiamo alla funzione del danno!
		_on_damage_taken(finta_hitbox)
