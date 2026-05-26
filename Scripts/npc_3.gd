extends CharacterBody2D

# --- IMPOSTAZIONI NPC ---
var speed: float = 80.0
var player_in_range: bool = false
var is_talking: bool = false
var player_target: Node2D = null

const PICKUP_ITEM_SCENE = preload("res://Scenes/pick_up_item.tscn")
var seeds: Array = [
	preload("res://Resources/seedcarrot/seedcarrot.tres"),
	preload("res://Resources/seedpotato/seedpotato.tres"),
	preload("res://Resources/seedwheat/seedwheat.tres")
]
var has_given_seed: bool = false

@export var npc_name: String = "Npc 3"
@export var storia_npc: Array[String] = [
	"Ehi tu! Lo sai che questa terra può ancora darci i suoi frutti, nonostante la corruzione?",
	"Ho imparato a coltivare piccoli semi nei terreni umidi. Basta zappare la terra soffice, piantarli e dar loro da bere.",
	"I frutti che crescono sono potentissimi! Non solo sfamano, ma alcuni possono aumentare la tua forza, la salute o la velocità in combattimento.",
	"Prendi, tieni questo. Provalo tu stesso. Forse è proprio la natura che ci salverà dal Mago Oscuro!"
]

# --- RIFERIMENTI AI NODI ---
@onready var exclamation_mark = $ExclamationMark
@onready var vision_area = $VisionArea
@onready var anim = $AnimatedSprite2D 

func _ready():
	# Nascondiamo il punto esclamativo all'inizio
	if exclamation_mark:
		exclamation_mark.visible = false

func _physics_process(delta):
	# Questo NPC non insegue più il giocatore, resta fermo e pacifico!
	pass

# --- L'AVVISTAMENTO (!) ---
# Assicurati di collegare il segnale "body_entered" della tua VisionArea a questa funzione!
func _on_vision_area_body_entered(body):
	if Global.talked_to_npc3: return
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = true
		player_target = body
		if exclamation_mark:
			exclamation_mark.visible = true

func _on_vision_area_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		player_in_range = false
		player_target = null
		if exclamation_mark:
			exclamation_mark.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not Global.talked_to_npc3:
		if player_in_range and not is_talking:
			get_viewport().set_input_as_handled()
			if exclamation_mark:
				exclamation_mark.visible = false
			inizia_dialogo()


func inizia_dialogo():
	is_talking = true
	velocity = Vector2.ZERO
	anim.stop()
	
	# BLOCCIAMO IL PLAYER!
	if player_target != null:
		player_target.can_move = false
	
	print("NPC ha raggiunto il player, inizia il dialogo!")
	
	if has_node("/root/DialogueManager"):
		var dm = DialogueManager
		dm.show_message(storia_npc, npc_name)
		await dm.dialogue_finished
		
		if not has_given_seed:
			has_given_seed = true
			Global.talked_to_npc3 = true
			_drop_random_seed()
			
		is_talking = false

func _drop_random_seed():
	var seed_to_drop = seeds[randi() % seeds.size()]
	var loot_drop = PICKUP_ITEM_SCENE.instantiate()
	
	loot_drop.inventory_item = seed_to_drop
	loot_drop.amount = 1
	loot_drop.item_id = ""
	loot_drop.z_index = -1
	loot_drop.y_sort_enabled = true
	
	get_parent().add_child(loot_drop)
	
	var start_pos = global_position
	var random_offset = Vector2(randf_range(-35.0, 35.0), randf_range(10.0, 30.0))
	var end_pos = start_pos + random_offset
	
	loot_drop.global_position = start_pos
	
	var tween_x = loot_drop.create_tween()
	tween_x.tween_property(loot_drop, "global_position:x", end_pos.x, 0.4)
	
	var tween_y = loot_drop.create_tween()
	var peak_y = min(start_pos.y, end_pos.y) - 25
	tween_y.tween_property(loot_drop, "global_position:y", peak_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(loot_drop, "global_position:y", end_pos.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func update_animation(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			anim.play("right_walking") # Cambia con il nome della tua animazione destra
		else:
			anim.play("left_walking")  # Cambia con il nome della tua animazione sinistra
	else:
		if dir.y > 0:
			anim.play("front_walking") # Animazione verso il basso
		else:
			anim.play("back_walking")  # Animazione verso l'alto
