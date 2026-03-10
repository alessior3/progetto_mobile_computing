extends CharacterBody2D
class_name Player
const speed = 100
var current_dir = "none"

@onready var inventory:Inventory=$Inventory

var house = null:
	set = set_house

func set_house(new_house):
	if new_house != null:
		$Key.show()
		$KeyPrompt.play("KeyPrompt")
	else:
		$Key.hide()
		$KeyPrompt.stop()
	house = new_house

# ECCO LA FUNZIONE FUSA E CORRETTA:
func _ready():
	# Aspettiamo che il TransitionManager e tutti gli altri nodi abbiano finito
	await get_tree().process_frame
	
	# --- 1. PRIORITÀ ASSOLUTA: CARICAMENTO CLOUD ---
	if SaveManager.is_loading_game:
		global_position = SaveManager.loaded_position
		SaveManager.is_loading_game = false
		Global.player_pos = Vector2.ZERO # Puliamo la memoria locale
		print("Player: Posizionato dal CLOUD")
		
	# --- 2. ENTRATA IN NEGOZIO/CASA (Se NON siamo nel mondo principale) ---
	# ATTENZIONE: Assicurati che la tua scena principale si chiami esattamente "world"
	elif get_tree().current_scene.name != "world":
		var spawn_marker = get_tree().current_scene.find_child("Marker2D", true, false)
		if spawn_marker:
			global_position = spawn_marker.global_position
			print("Player: Posizionato sul Marker del negozio")
		# NON azzeriamo Global.player_pos qui! Ci servirà intatto per quando usciamo.

	# --- 3. RITORNO AL MONDO ESTERNO (Uscita dal negozio) ---
	elif Global.player_pos != Vector2.ZERO:
		global_position = Global.player_pos
		Global.player_pos = Vector2.ZERO # DOPO averlo usato per tornare fuori, lo SVUOTIAMO!
		print("Player: Posizionato dalla PORTA")

	# --- Impostazione Dinamica della Direzione ---
	if Global.get("player_facing_dir") != null:
		current_dir = Global.player_facing_dir
	else:
		current_dir = "down" # Direzione di sicurezza
		
	play_anim(0)
	set_house(null)

	if has_node("Label"):
		$Label.text = Global.current_username

func _unhandled_input(event):
	# Codice originale per entrare in casa
	if event is InputEventKey and event.is_action_pressed("interact") and house != null:
		house.enter()
		
	# --- NUOVO: SALVATAGGIO CON TASTO K ---
	# Se premi il tasto K sulla tastiera, salva la posizione e il gioco!
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		Global.player_pos = global_position
		SaveManager.save_game()




func _physics_process(delta):
	# --- GESTIONE LUCE TORCIA ---
	# Controlla se hai un oggetto in mano e se si chiama esattamente "Torch"
	var hand_item = Global.persistent_hand
	if has_node("TorchLight"):
		$TorchLight.visible = (hand_item != null and hand_item.name == "Torch" or hand_item != null and hand_item.name == "Torcia")
	
	# ... il tuo codice di movimento esistente ...
	player_movement(delta)

func player_movement(delta):
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		play_anim(1)
		velocity.x = speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		play_anim(1)
		velocity.x = -speed
		velocity.y = 0
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		play_anim(1)
		velocity.y = speed
		velocity.x = 0
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		play_anim(1)
		velocity.y = -speed
		velocity.x = 0
	else:
		play_anim(0)
		velocity = Vector2.ZERO

	move_and_slide()

func play_anim(movement):
	var dir = current_dir
	var anim = $AnimatedSprite2D

	if dir == "right":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_side")
		else:
			anim.play("idle_side")
	if dir == "left":
		anim.flip_h = false
		if movement == 1:
			anim.play("walk_side")
		else:
			anim.play("idle_side")
	if dir == "down":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_front")
		else:
			anim.play("idle_front")
	if dir == "up":
		anim.flip_h = true
		if movement == 1:
			anim.play("walk_back")
		else:
			anim.play("idle_back")
