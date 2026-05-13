@tool
extends Node2D
class_name ArenaManager

@export_category("Arena Settings")
@export var enemy_types: Array[PackedScene]
@export var waves_count: int = 3
@export var enemies_per_wave: int = 4
@export var time_between_waves: float = 2.0
@export var random_spawn_area: Vector2 = Vector2(50, 50):
	set(value):
		random_spawn_area = value
		queue_redraw()

# --- NUOVE IMPOSTAZIONI PER IL BOSS ---
@export_category("Boss Settings")
@export var is_boss_arena: bool = false
@export var boss_node: Node2D 

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
	if Engine.is_editor_hint():
		return 
		
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_entered)
		
	for door in doors:
		if door:
			if door.has_method("open_door"):
				# Se la porta ha la spunta "start_closed", ignora l'apertura iniziale
				if "start_closed" in door and door.start_closed:
					continue
				door.open_door()
			else:
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
		trigger_area.queue_free() 
	
	print("Arena avviata! Attendiamo che il player entri...")
	emit_signal("arena_started")
	
	if get_tree() == null: return
	await get_tree().create_timer(0.4).timeout
	
	for door in doors:
		if door:
			if door.has_method("close_door"):
				door.close_door()
			else:
				door.process_mode = Node.PROCESS_MODE_INHERIT
				door.show()
			
	if get_tree() == null: return
	await get_tree().create_timer(0.6).timeout
	
	# --- BIVIO: ONDATE O BOSS? ---
	if is_boss_arena:
		if boss_node:
			print("Modalità Boss! Attendiamo la caduta del boss...")
			# Ascoltiamo la morte del boss!
			boss_node.tree_exited.connect(_on_boss_died)
			
			# --- SVEGLIAMO IL BOSS! ---
			if boss_node.has_method("activate_boss"):
				boss_node.activate_boss()
		else:
			print("ERRORE: Hai spuntato is_boss_arena ma non hai assegnato il Boss!")
	else:
		start_wave()

# --- FUNZIONE SPECIALE BOSS MORTO ---
func _on_boss_died():
	if not arena_active: return
	print("IL BOSS È STATO SCONFITTO! Vittoria!")
	finish_arena()


func start_wave():
	current_wave += 1
	if current_wave > waves_count:
		finish_arena()
		return
		
	print("Inizio ondata ", current_wave, " di ", waves_count)
	enemies_alive = enemies_per_wave
	
	for i in range(enemies_per_wave):
		if enemy_types.is_empty():
			break
			
		var enemy_scene = enemy_types.pick_random() as PackedScene
		if not enemy_scene: continue
		
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position
		
		if spawn_points.size() > 0:
			spawn_pos = spawn_points.pick_random().global_position 
		else:
			var valid_spawn = false
			var attempts = 0
			var space_state = get_world_2d().direct_space_state
			
			while not valid_spawn and attempts < 15:
				var test_pos = global_position + Vector2(randf_range(-random_spawn_area.x, random_spawn_area.x), randf_range(-random_spawn_area.y, random_spawn_area.y))
				
				var query = PhysicsPointQueryParameters2D.new()
				query.position = test_pos
				query.collision_mask = 1
				
				var results = space_state.intersect_point(query)
				if results.is_empty():
					valid_spawn = true
					spawn_pos = test_pos
					
				attempts += 1
				
			if not valid_spawn:
				spawn_pos = global_position
		
		enemy.global_position = spawn_pos
		enemy.add_to_group("arena_enemy")
		
		if "chases_player" in enemy:
			enemy.chases_player = true
		
		enemy.tree_exited.connect(_on_enemy_died)
		get_parent().call_deferred("add_child", enemy)
		
		if get_tree() == null: return
		await get_tree().create_timer(0.2).timeout

func _on_enemy_died():
	if not arena_active or is_boss_arena: return # Se è un boss, ignoriamo questa funzione
	
	enemies_alive -= 1
	
	if enemies_alive <= 0:
		emit_signal("wave_cleared", current_wave)
		
		if current_wave < waves_count:
			if get_tree() == null: return
			await get_tree().create_timer(time_between_waves).timeout
			start_wave()
		else:
			start_wave() 

func finish_arena():
	arena_active = false
	arena_cleared = true
	print("Arena completata! Porte aperte.")
	emit_signal("arena_cleared_signal")
	
	# Riapriamo TUTTE le porte!
	for door in doors:
		if door:
			if door.has_method("open_door"):
				door.open_door()
			else:
				door.process_mode = Node.PROCESS_MODE_DISABLED
				door.hide()

func _draw():
	if Engine.is_editor_hint():
		draw_rect(Rect2(-random_spawn_area.x, -random_spawn_area.y, random_spawn_area.x * 2, random_spawn_area.y * 2), Color(1.0, 0.2, 0.2, 0.2), false, 2.0)
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color(1.0, 0.2, 0.2, 0.5), 1.0)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color(1.0, 0.2, 0.2, 0.5), 1.0)
