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

var original_camera_zoom: Vector2 = Vector2.ONE
var player_camera: Camera2D = null

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
				# Se la porta ha la spunta "start_closed" o "requires_gems", ignora l'apertura iniziale
				var should_stay_closed = ("start_closed" in door and door.start_closed) or ("requires_gems" in door and door.requires_gems)
				if should_stay_closed:
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
	
	print("Arena avviata a pos: ", global_position, "! Attendiamo che il player entri...")
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
				
			# --- ZOOM OUT DELLA CAMERA ---
			var player = get_tree().get_first_node_in_group("player")
			if not player: player = get_tree().get_first_node_in_group("Player")
			if player:
				player_camera = player.get_node_or_null("Camera2D")
				if not player_camera:
					player_camera = player.get_node_or_null("playerCamera")
				
				if player_camera:
					original_camera_zoom = player_camera.zoom
					var tween = create_tween()
					# 0.65 allarga ancora di più la visuale
					tween.tween_property(player_camera, "zoom", original_camera_zoom * 0.65, 2.0).set_trans(Tween.TRANS_SINE)
		else:
			print("ERRORE: Hai spuntato is_boss_arena ma non hai assegnato il Boss!")
	else:
		start_wave()

# --- FUNZIONE SPECIALE BOSS MORTO ---
func _on_boss_died():
	if not arena_active: return
	print("IL BOSS È STATO SCONFITTO! Vittoria!")
	
	# --- RIPRISTINO ZOOM DELLA CAMERA ---
	if player_camera:
		var tween = create_tween()
		tween.tween_property(player_camera, "zoom", original_camera_zoom, 2.0).set_trans(Tween.TRANS_SINE)
		
	finish_arena()


func start_wave():
	current_wave += 1
	if current_wave > waves_count:
		finish_arena()
		return
		
	print("DEBUG: Inizio ondata ", current_wave, " di ", waves_count)
	enemies_alive = 0 # Iniziamo da 0 e contiamo solo quelli spawnati davvero
	
	if enemy_types.is_empty():
		print("DEBUG: ERRORE! L'array enemy_types è VUOTO. Impossibile spawnare nemici.")
		finish_arena()
		return
	
	for i in range(enemies_per_wave):
			
		var enemy_scene = enemy_types.pick_random() as PackedScene
		if not enemy_scene: continue
		
		var enemy = enemy_scene.instantiate()
		var spawn_pos = global_position
		
		if spawn_points.size() > 0:
			var point = spawn_points.pick_random()
			spawn_pos = point.global_position 
			print("DEBUG: Utilizzo SpawnPoint: ", point.name, " a pos: ", spawn_pos)
		else:
			print("DEBUG: Nessun SpawnPoint trovato. Calcolo posizione casuale nell'area ", random_spawn_area)
			var valid_spawn = false
			var attempts = 0
			var space_state = get_world_2d().direct_space_state
			
			while not valid_spawn and attempts < 15:
				var offset = Vector2(randf_range(-random_spawn_area.x, random_spawn_area.x), randf_range(-random_spawn_area.y, random_spawn_area.y))
				var test_pos = global_position + offset
				
				var query = PhysicsPointQueryParameters2D.new()
				query.position = test_pos
				query.collision_mask = 1
				
				var results = space_state.intersect_point(query)
				if results.is_empty():
					valid_spawn = true
					spawn_pos = test_pos
					print("DEBUG: Posizione valida trovata al tentativo ", attempts, " con offset ", offset)
				
				attempts += 1
				
			if not valid_spawn:
				print("DEBUG: ATTENZIONE! Nessuna posizione valida trovata dopo 15 tentativi. Uso global_position.")
				spawn_pos = global_position
		
		enemy.tree_exited.connect(_on_enemy_died)
		get_parent().add_child(enemy)
		
		# Configurazioni nemico
		enemy.global_position = spawn_pos
		enemy.add_to_group("arena_enemy")
		if "chases_player" in enemy:
			enemy.chases_player = true
			
		enemies_alive += 1 
		print("DEBUG: Nemico ", i+1, "/", enemies_per_wave, " spawnato a ", enemy.global_position)
		
		if get_tree() == null: return
		await get_tree().create_timer(0.2).timeout
		
	if enemies_alive == 0:
		print("DEBUG: ATTENZIONE! Nessun nemico spawnato nell'ondata. Salto all'ondata successiva...")
		_on_enemy_died() # Forza il passaggio se lo spawn fallisce

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
	# L'uscita ai titoli di coda è gestita direttamente dallo script 
	# "transition_area.gd" assegnato al nodo "exit"!
	
	# Riapriamo TUTTE le porte!
	arena_cleared = true
	print("Arena completata! Porte aperte.")
	emit_signal("arena_cleared_signal")
	# Non facciamo affidamento al body_entered per via delle collision mask,
	# gestiamo la distanza nell' _process!
	
	# Riapriamo TUTTE le porte!
	for door in doors:
		if door:
			if door.has_method("open_door"):
				door.open_door()
			else:
				door.process_mode = Node.PROCESS_MODE_DISABLED
				door.hide()

func _process(delta):
	pass

func _draw():
	if Engine.is_editor_hint():
		draw_rect(Rect2(-random_spawn_area.x, -random_spawn_area.y, random_spawn_area.x * 2, random_spawn_area.y * 2), Color(1.0, 0.2, 0.2, 0.2), false, 2.0)
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color(1.0, 0.2, 0.2, 0.5), 1.0)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color(1.0, 0.2, 0.2, 0.5), 1.0)
