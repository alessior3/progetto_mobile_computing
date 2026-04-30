extends Node2D
class_name ArenaManager

@export_category("Arena Settings")
@export var enemy_types: Array[PackedScene]
@export var waves_count: int = 3
@export var enemies_per_wave: int = 4
@export var time_between_waves: float = 2.0

@export_category("Scene References")
@export var doors: Array[StaticBody2D] # Muri invisibili o cancelli da attivare
@export var spawn_points: Array[Marker2D] # Dove appariranno i nemici

var current_wave: int = 0
var enemies_alive: int = 0
var arena_active: bool = false
var arena_cleared: bool = false

@onready var trigger_area: Area2D = $TriggerArea

signal arena_started
signal wave_cleared(wave_num)
signal arena_cleared_signal

func _ready():
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_entered)
		
	# Assicuriamoci che le porte siano aperte all'inizio (disabilitate)
	for door in doors:
		if door:
			door.process_mode = Node.PROCESS_MODE_DISABLED
			door.hide()

func _on_trigger_entered(body: Node2D):
	if arena_cleared or arena_active:
		return
		
	if body.is_in_group("player"):
		start_arena()

func start_arena():
	arena_active = true
	if trigger_area:
		trigger_area.queue_free() # Rimuoviamo il trigger per non riattivarlo
	
	print("Arena avviata! Porte chiuse.")
	emit_signal("arena_started")
	
	# Chiudiamo le porte (abilitiamo la collisione e mostriamo l'oggetto)
	for door in doors:
		if door:
			door.process_mode = Node.PROCESS_MODE_INHERIT
			door.show()
			
	# Piccola pausa drammatica prima che inizino i mostri
	await get_tree().create_timer(1.0).timeout
	start_wave()

func start_wave():
	current_wave += 1
	if current_wave > waves_count:
		finish_arena()
		return
		
	print("Inizio ondata ", current_wave, " di ", waves_count)
	enemies_alive = enemies_per_wave
	
	for i in range(enemies_per_wave):
		if enemy_types.is_empty():
			print("ATTENZIONE: Nessun tipo di nemico assegnato all'ArenaManager!")
			break
			
		var enemy_scene = enemy_types.pick_random() as PackedScene
		if not enemy_scene: continue
		
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position
		
		if spawn_points.size() > 0:
			spawn_pos = spawn_points.pick_random().global_position 
		else:
			# Se non ci sono marker, spawna in posizioni casuali vicine
			spawn_pos += Vector2(randf_range(-50, 50), randf_range(-50, 50))
		
		enemy.global_position = spawn_pos
		enemy.add_to_group("arena_enemy")
		
		# Abilita "chases_player" se disponibile per renderli aggressivi
		if "chases_player" in enemy:
			enemy.chases_player = true
		
		# Ascoltiamo l'eliminazione del nodo per contare le uccisioni
		enemy.tree_exited.connect(_on_enemy_died)
		
		# Lo aggiungiamo al padre del manager (es. la root del dungeon) per l'Y-Sort
		get_parent().call_deferred("add_child", enemy)
		
		# Piccolo stagger nello spawn
		await get_tree().create_timer(0.2).timeout

func _on_enemy_died():
	if not arena_active: return
	
	enemies_alive -= 1
	print("Nemico arena ucciso! Restanti nell'ondata: ", enemies_alive)
	
	if enemies_alive <= 0:
		emit_signal("wave_cleared", current_wave)
		print("Ondata ", current_wave, " completata!")
		
		# Pausa prima della prossima ondata
		if current_wave < waves_count:
			await get_tree().create_timer(time_between_waves).timeout
			start_wave()
		else:
			# Se era l'ultima ondata, chiama subito la fine
			start_wave() # La start_wave capirà che siamo oltre count e chiamerà finish_arena

func finish_arena():
	arena_active = false
	arena_cleared = true
	print("Arena completata! Porte aperte.")
	emit_signal("arena_cleared_signal")
	
	# Riapri le porte
	for door in doors:
		if door:
			door.process_mode = Node.PROCESS_MODE_DISABLED
			door.hide()
