extends Node2D

class_name BinaryLogicManager

signal solved

@export var target_decimal: int = 0
@export var current_binary_sum: int = 0
@export var target_node_path: NodePath
@export var interaction_radius: float = 100.0

@export_category("Easter Egg Settings")
@export var easter_egg_enemies: Array[PackedScene] = []
@export var easter_egg_spawn_count: int = 6

const TERMINAL_SCENE_PATH = "res://Scenes/UI/stone_terminal.tscn"
const DEFAULT_PHANTOM = preload("res://Scenes/phantom.tscn")
const DEFAULT_SPIDER = preload("res://Scenes/spider.tscn")

@onready var bus_lines = $BusLines
@onready var proximity_area = get_node_or_null("ProximityArea")

var player_in_range_of_altar = false

var bits = {1: 0, 2: 0, 4: 0, 8: 0}

func _ready():
	# Genera un numero casuale tra 1 e 15 (4 bit)
	randomize()
	target_decimal = randi_range(1, 15)
	
	if not proximity_area:
		print("DEBUG: ProximityArea mancante, la creo via codice...")
		proximity_area = Area2D.new()
		proximity_area.name = "ProximityArea"
		proximity_area.collision_layer = 0
		proximity_area.collision_mask = 2 # Player
		add_child(proximity_area)
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = interaction_radius
		shape.shape = circle
		proximity_area.add_child(shape)
	else:
		# Se il nodo esiste gia', aggiorniamo comunque il raggio da quello impostato nell'Inspector
		var shape_node = proximity_area.get_child(0)
		if shape_node and shape_node is CollisionShape2D:
			if shape_node.shape is CircleShape2D:
				shape_node.shape.radius = interaction_radius
	
	if bus_lines:
		bus_lines.z_index = 10 # Porta le linee sopra il pavimento e i tile
		print("DEBUG: BusLines portati in primo piano (Z-Index 10)")
	
	if proximity_area:
		print("DEBUG: ProximityArea pronta.")
		if not proximity_area.body_entered.is_connected(_on_proximity_entered):
			proximity_area.body_entered.connect(_on_proximity_entered)
		if not proximity_area.body_exited.is_connected(_on_proximity_exited):
			proximity_area.body_exited.connect(_on_proximity_exited)
	
	print("DEBUG: Puzzle Binario Iniziato. Target: ", target_decimal)
	
	# Cerchiamo tutti i socket nel gruppo "binary_sockets"
	var sockets = get_tree().get_nodes_in_group("binary_sockets")
	for socket in sockets:
		if socket is BinarySocket:
			if not socket.power_changed.is_connected(_on_bit_changed):
				socket.power_changed.connect(_on_bit_changed.bind(socket.bit_value))

func _on_bit_changed(value: int, bit_id: int):
	bits[bit_id] = value
	_calculate_sum()
	_update_bus_visuals()

func _calculate_sum():
	current_binary_sum = 0
	for val in bits.values():
		current_binary_sum += val
	
	print("DEBUG: Somma Binaria Corrente: ", current_binary_sum, " / Target: ", target_decimal)
	
	if current_binary_sum == target_decimal:
		_on_solved()
	else:
		_on_unsolved()

func _update_bus_visuals():
	# Qui accendiamo le Line2D in base ai bit
	if not bus_lines: return
	
	for bit_id in bits.keys():
		var line = bus_lines.get_node_or_null("Line" + str(bit_id))
		if line and line is Line2D:
			if bits[bit_id] > 0:
				line.default_color = Color(0, 1, 1, 1) # Cyan acceso
				line.width = 2.0
			else:
				line.default_color = Color(0.2, 0.2, 0.2, 1) # Grigio spento
				line.width = 1.0

func _on_solved():
	print("DEBUG: PUZZLE RISOLTO!")
	solved.emit()
	
	var target_node = get_node_or_null(target_node_path)
	if target_node:
		if target_node.has_method("unlock"):
			target_node.unlock()
		elif target_node.has_method("open_door"):
			target_node.open_door()
			
	# Blocca tutti i socket per impedire di riprendersi l'oro!
	var sockets = get_tree().get_nodes_in_group("binary_sockets")
	for socket in sockets:
		if socket is BinarySocket:
			socket.is_locked = true
			
			# Nasconde la "E" se il player era vicino
			if socket.player_ref and socket.player_ref.has_node("Key"):
				socket.player_ref.get_node("Key").hide()
			if socket.player_ref and socket.player_ref.has_node("KeyPrompt"):
				socket.player_ref.get_node("KeyPrompt").play_backwards("KeyPrompt")
			
	# Illumina i bus (flusso di energia) verso la cassa/porta
	if bus_lines:
		print("DEBUG: Attivazione bus energetici...")
		var tween = create_tween()
		for line in bus_lines.get_children():
			if line is Line2D:
				# Diventa ciano brillante e raddoppia lo spessore
				tween.parallel().tween_property(line, "default_color", Color(0, 4, 4, 1), 0.8).set_trans(Tween.TRANS_SINE)
				tween.parallel().tween_property(line, "width", line.width * 2.0, 0.4)

func _on_unsolved():
	var target_node = get_node_or_null(target_node_path)
	if target_node:
		if target_node.has_method("lock"):
			target_node.lock()
		elif target_node.has_method("close_door"):
			target_node.close_door()
	
func _on_proximity_entered(body):
	print("DEBUG: Qualcosa e' entrato nell'area dell'altare: ", body.name)
	if body.is_in_group("player") or body.name == "player":
		player_in_range_of_altar = true
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_proximity_exited(body):
	if body.is_in_group("player") or body.name == "player":
		player_in_range_of_altar = false
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play_backwards("KeyPrompt")

func _input(event):
	if player_in_range_of_altar and event.is_action_pressed("interact"):
		print("DEBUG: Tasto Interact premuto per aprire il terminale!")
		_open_terminal()
		get_viewport().set_input_as_handled() # Impedisce alla 'e' di finire nel terminale

func _open_terminal():
	# Evita di aprire più terminali
	if get_tree().get_nodes_in_group("terminal").size() > 0: 
		print("DEBUG: Terminale gia' aperto, ignoro.")
		return
	
	if not FileAccess.file_exists(TERMINAL_SCENE_PATH):
		print("DEBUG: ERRORE! Scena terminale non trovata a: ", TERMINAL_SCENE_PATH)
		return

	var terminal_res = load(TERMINAL_SCENE_PATH)
	if terminal_res:
		print("DEBUG: Scena caricata, istanzio...")
		var terminal = terminal_res.instantiate()
		terminal.add_to_group("terminal")
		get_tree().root.add_child(terminal)
		terminal.setup(target_decimal)
		
		# BLOCCA IL GIOCO
		get_tree().paused = true
		terminal.terminal_closed.connect(func(): get_tree().paused = false)
		terminal.sudo_triggered.connect(_on_sudo_triggered)
		terminal.sudo_open_triggered.connect(_on_sudo_open_triggered)
		
		print("DEBUG: Terminale aggiunto e gioco in pausa!")
	else:
		print("DEBUG: ERRORE! Fallito il caricamento della risorsa terminale.")

func _on_sudo_triggered():
	print("DEBUG: Sudo bypass rilevato. Risveglio dei guardiani...")
	
	var parent_node = get_parent() 
	var num_enemies = easter_egg_spawn_count
	var radius = interaction_radius + 40.0
	var space_state = get_world_2d().direct_space_state
	
	for i in range(num_enemies):
		var enemy_scene: PackedScene
		if not easter_egg_enemies.is_empty():
			enemy_scene = easter_egg_enemies.pick_random()
		else:
			enemy_scene = DEFAULT_PHANTOM if randf() > 0.5 else DEFAULT_SPIDER
			
		if not enemy_scene: continue
		
		var spawn_pos = global_position
		
		# Troviamo il player e spawniamo i nemici più in basso rispetto a lui (Y positivo in Godot)
		var player = get_tree().get_first_node_in_group("player")
		if player:
			spawn_pos = player.global_position + Vector2(randf_range(-25.0, 25.0), 30.0)
		
		var enemy = enemy_scene.instantiate()
		parent_node.add_child(enemy)
		enemy.global_position = spawn_pos
		
		if "chases_player" in enemy:
			enemy.chases_player = true
			
		# Evitiamo che i nemici dell'easter egg droppino oggetti per non far farmare il player
		if "item_to_drop" in enemy:
			enemy.item_to_drop = null
			
		print("DEBUG: Nemico spawnato a: ", enemy.global_position)

func _on_sudo_open_triggered():
	print("DEBUG: Sudo Open (God Mode) attivato!")
	_on_bit_changed(0, 0) # Triggera un check immediato (opzionale)
	
	# Sblocca forzatamente il target
	var target_node = get_node_or_null(target_node_path)
	if target_node:
		if target_node.has_method("unlock"):
			target_node.unlock()
		elif target_node.has_method("open_door"):
			target_node.open_door()
	
	# Nota: Non blocchiamo i socket qui, lasciamo che il player faccia quello che vuole in God Mode
