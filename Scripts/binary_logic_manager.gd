extends Node2D

class_name BinaryLogicManager

signal solved

@export var target_decimal: int = 0
@export var current_binary_sum: int = 0
@export var door_to_open: NodePath
const TERMINAL_SCENE = preload("res://Scenes/UI/stone_terminal.tscn")

@onready var label_target = $LabelTarget
@onready var bus_lines = $BusLines
@onready var proximity_area = get_node_or_null("ProximityArea")

var player_in_range_of_altar = false

var bits = {1: 0, 2: 0, 4: 0, 8: 0}

func _ready():
	# Genera un numero casuale tra 1 e 15 (4 bit)
	randomize()
	target_decimal = randi_range(1, 15)
	
	if label_target:
		label_target.text = "Tocca l'Altare per interrogare il Kernel..."
		label_target.hide()
	
	if proximity_area:
		proximity_area.body_entered.connect(_on_proximity_entered)
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
	print("DEBUG: PUZZLE RISOLTO! Apertura porta...")
	solved.emit()
	
	if label_target:
		label_target.add_theme_color_override("font_color", Color(0, 1, 0)) # Verde puro
	
	var door = get_node_or_null(door_to_open)
	if door and door.has_method("open_door"):
		door.open_door()
	
func _on_proximity_entered(body):
	if body.is_in_group("player"):
		player_in_range_of_altar = true
		if label_target: label_target.show()

func _on_proximity_exited(body):
	if body.is_in_group("player"):
		player_in_range_of_altar = false
		if label_target: label_target.hide()

func _input(event):
	if player_in_range_of_altar and event.is_action_pressed("interact"):
		_open_terminal()

func _open_terminal():
	# Evita di aprire più terminali
	if get_tree().get_nodes_in_group("terminal").size() > 0: return
	
	var terminal = TERMINAL_SCENE.instantiate()
	terminal.add_to_group("terminal")
	get_tree().root.add_child(terminal)
	terminal.setup(target_decimal)
