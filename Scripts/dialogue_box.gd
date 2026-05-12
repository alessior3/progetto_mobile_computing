extends CanvasLayer

signal dialogue_finished

@onready var text_label = $TextureRect/Panel/Label 
@onready var background = $TextureRect 

var can_skip: bool = false

# --- NUOVE VARIABILI PER LE PAGINE ---
var pages: Array = []
var current_page: int = 0
var current_tween: Tween

func _ready():
	hide() 

# Ora accetta sia una stringa singola che un Array di stringhe!
func show_message(dialogue_data):
	print("--- DEBUG DIALOGO ---")
	print("Dato ricevuto dall'NPC: ", dialogue_data)
	
	# In Godot 4, 'is' è molto più infallibile di 'typeof()' per riconoscere gli Array
	if dialogue_data is String:
		pages = [dialogue_data]
		print("Risultato: Godot lo sta ancora leggendo come SINGOLA STRINGA (Pagina unica)")
	elif dialogue_data is Array:
		pages = dialogue_data
		print("Risultato: Godot lo sta leggendo correttamente come ARRAY (Più pagine)")
	else:
		return
		
	current_page = 0
	can_skip = false
	
	# --- LA MAGIA FORZATA ---
	# Obblighiamo Godot ad applicare l'andata a capo e l'allineamento in alto da codice!
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	# 1. Blocchiamo il player
	var player = get_tree().get_first_node_in_group("player")
	if player == null: player = get_tree().get_first_node_in_group("Player")
	
	if player != null and "can_move" in player:
		player.can_move = false

	# Mostriamo la grafica
	background.show()
	$TextureRect/Panel.show()
	text_label.show()
	show()
	
	# Facciamo partire la prima riga
	play_current_page()
	
func play_current_page():
	can_skip = false
	
	# 2. Prepariamo il testo
	text_label.text = pages[current_page]
	text_label.visible_characters = 0
	
	# Stoppiamo la vecchia animazione se clicchi molto velocemente
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	# 4. Effetto macchina da scrivere
	current_tween = get_tree().create_tween()
	current_tween.tween_property(text_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# 5. Timer di sicurezza (mezzo secondo) prima di poter passare oltre
	await get_tree().create_timer(0.5).timeout
	can_skip = true


# --- IL SEGRETO È QUI: Usiamo _input invece di _process! ---
func _input(event):
	if not background.visible or not can_skip:
		return
		
	if event.is_action_pressed("interact") or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		
		get_viewport().set_input_as_handled() 
		
		# --- CONTROLLO PAGINE ALLA POKÉMON ---
		if current_page < pages.size() - 1:
			# Se ci sono ancora pagine, vai alla successiva
			current_page += 1
			play_current_page()
		else:
			# Se le pagine sono finite, chiudi tutto
			close_dialogue()
			dialogue_finished.emit()


func close_dialogue():
	can_skip = false
	hide() 
	background.hide() 
	
	# Sblocchiamo il player!
	var player = get_tree().get_first_node_in_group("player")
	if player == null: player = get_tree().get_first_node_in_group("Player")
	
	if player != null and "can_move" in player:
		player.can_move = true
		print("Dialogo chiuso, il Player è di nuovo libero!")
