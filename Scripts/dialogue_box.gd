extends CanvasLayer

signal dialogue_finished

@onready var text_label = $TextureRect/Panel/Label 
@onready var name_label = $NameLabel
@onready var background = $TextureRect 

var can_skip: bool = false

# --- NUOVE VARIABILI PER LE PAGINE ---
var pages: Array = []
var current_page: int = 0
var current_tween: Tween
var current_speaker: String = ""
var current_allow_skip: bool = true

# Forza la configurazione della label del nome a runtime in modo impermeabile ai bug di cache di Godot!
func _ready():
	hide() 
	
	var settings = LabelSettings.new()
	settings.font_size = 17
	settings.font_color = Color(0.98, 0.96, 0.9, 1)
	settings.outline_size = 4
	settings.outline_color = Color(0.08, 0.05, 0.03, 1)
	
	name_label.label_settings = settings
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	# Centratura pixel-perfect orizzontale e verticale basata sulla targhetta originale
	name_label.offset_left = 22.0
	name_label.offset_right = 142.0
	name_label.offset_top = -116.0
	name_label.offset_bottom = -96.0

# Accetta il testo del dialogo e opzionalmente il nome del parlante!
func show_message(dialogue_data, speaker: String = "", block_player: bool = true, allow_skip: bool = true):
	print("--- DEBUG DIALOGO ---")
	print("Dato ricevuto dall'NPC: ", dialogue_data)
	print("Parlante ricevuto: ", speaker)
	
	if dialogue_data is String:
		pages = [dialogue_data]
	elif dialogue_data is Array:
		pages = dialogue_data
	else:
		return
		
	current_page = 0
	can_skip = false
	current_speaker = speaker
	current_allow_skip = allow_skip
	
	# Obblighiamo Godot ad applicare l'andata a capo e la centratura verticale da codice!
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 1. Blocchiamo il player se richiesto
	if block_player:
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
	
	var page_text = pages[current_page]
	var speaker_name = current_speaker
	var dialogue_text = page_text
	
	# Fallback intelligente: se non c'è un nome esplicito ma c'è un prefisso "Nome:", lo estrae
	if speaker_name == "":
		var colon_idx = page_text.find(":")
		if colon_idx != -1 and colon_idx < 25:
			speaker_name = page_text.left(colon_idx).strip_edges()
			dialogue_text = page_text.substr(colon_idx + 1).strip_edges()
		
	if speaker_name != "":
		name_label.text = speaker_name
		name_label.show()
	else:
		name_label.text = ""
		name_label.hide()
	
	# 2. Prepariamo il testo del dialogo
	text_label.text = dialogue_text
	text_label.visible_characters = 0
	
	# Stoppiamo la vecchia animazione se clicchi molto velocemente
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	# 4. Effetto macchina da scrivere
	current_tween = get_tree().create_tween()
	current_tween.tween_property(text_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# 5. Timer di sicurezza (mezzo secondo) prima di poter passare oltre
	await get_tree().create_timer(0.5).timeout
	if current_allow_skip:
		can_skip = true

# Permette di aggiornare il testo direttamente (ad esempio per una progress bar) senza animazioni
func update_text_direct(new_text: String):
	text_label.text = new_text
	text_label.visible_ratio = 1.0


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
