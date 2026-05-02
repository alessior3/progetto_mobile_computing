extends CanvasLayer

@onready var text_label = $TextureRect/Panel/Label 
@onready var background = $TextureRect 

var can_skip: bool = false

func _ready():
	hide() 

func show_message(text: String):
	can_skip = false
	
	# 1. Blocchiamo il player
	var player = get_tree().get_first_node_in_group("player")
	if player == null: player = get_tree().get_first_node_in_group("Player")
	
	if player != null and "can_move" in player:
		player.can_move = false

	# 2. Prepariamo il testo
	text_label.text = text
	text_label.visible_characters = 0
	
	# 3. Mostriamo la grafica
	background.show()
	$TextureRect/Panel.show()
	text_label.show()
	show()
	
	# 4. Effetto macchina da scrivere
	var tween = get_tree().create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	
	# 5. Timer di sicurezza (mezzo secondo) prima di poter chiudere
	await get_tree().create_timer(0.5).timeout
	can_skip = true

# --- IL SEGRETO È QUI: Usiamo _input invece di _process! ---
# _input intercetta i tocchi sullo schermo istantaneamente
func _input(event):
	# Se il dialogo non è aperto o non possiamo ancora skippare, ignora
	if not background.visible or not can_skip:
		return
		
	# Se preme "interact" OPPURE tocca un punto qualsiasi dello schermo OPPURE fa clic:
	if event.is_action_pressed("interact") or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		
		# Diciamo a Godot "Ho gestito io questo tocco", così il player non attacca per sbaglio
		get_viewport().set_input_as_handled() 
		
		close_dialogue()


func close_dialogue():
	can_skip = false
	hide() 
	background.hide() # Doppia sicurezza per nascondere la grafica
	
	# Sblocchiamo il player!
	var player = get_tree().get_first_node_in_group("player")
	if player == null: player = get_tree().get_first_node_in_group("Player")
	
	if player != null and "can_move" in player:
		player.can_move = true
		print("Dialogo chiuso, il Player è di nuovo libero!")
