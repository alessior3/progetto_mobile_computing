extends CharacterBody2D

var has_spotted_player: bool = false
var is_talking: bool = false

@export var npc_name: String = "Npc Prete 2"
@export var storia_npc: Array[String] = [
	"Che la Luce sia con te, prescelto. Sapevo che saresti arrivato fin qui, al confine del mondo conosciuto.",
	"L'ingresso per il Dungeon Finale, la tana del Mago Oscuro, non si trova in alcun castello visibile...",
	"È nascosto nei meandri sotterranei di una casa sperduta nel nulla. Un luogo dimenticato da tutti, avvolto nell'oscurità più profonda.",
	"Per fronteggiare le mostruosità che troverai laggiù, la tua attuale lama non basterà.",
	"Prendi questa: è la leggendaria Big Sword. Che possa tagliare le tenebre e riportare finalmente la pace."
]

@onready var exclamation_mark = get_node_or_null("ExclamationMark")
@onready var anim = get_node_or_null("AnimatedSprite2D")

func _ready():
	if anim:
		anim.play("back_an")
	if exclamation_mark:
		exclamation_mark.visible = false

func _on_vision_area_body_entered(body):
	if Global.get("talked_to_npc_prete2"): return
	
	if body.name == "Player" or body.name == "player" or body.is_in_group("Player") or body.is_in_group("player"):
		has_spotted_player = true
		if anim:
			anim.play("idle_an")
		if exclamation_mark:
			exclamation_mark.visible = true
			
		# Breve attesa per effetto scenico
		await get_tree().create_timer(0.5).timeout
		if exclamation_mark:
			exclamation_mark.visible = false
			
		inizia_dialogo()

func inizia_dialogo():
	is_talking = true
	velocity = Vector2.ZERO
	
	# BLOCCIAMO IL PLAYER
	var player_target = get_tree().get_first_node_in_group("player")
	if player_target != null and "can_move" in player_target:
		player_target.can_move = false
		
	var dm = null
	if has_node("/root/DialogueManager"):
		dm = get_node("/root/DialogueManager")
	
	if dm:
		dm.show_message(storia_npc, npc_name)
		await dm.dialogue_finished
		Global.set("talked_to_npc_prete2", true)
		
		if anim:
			anim.play("back_an")
			
		# DROPPPIAMO LA SPADA MAGGIORE (CON ANIMAZIONE)
		var pick_up_scene = load("res://Scenes/pick_up_item.tscn")
		if pick_up_scene:
			var drop = pick_up_scene.instantiate()
			drop.inventory_item = load("res://Resources/weapons/Big_Sword.tres")
			drop.item_id = "big_sword_villaggio4" # per evitare che respawni all'infinito
			drop.z_index = -1
			drop.y_sort_enabled = true
			
			get_parent().add_child(drop)
			
			var start_pos = global_position
			var end_pos = start_pos + Vector2(0, 40)
			
			drop.global_position = start_pos
			
			# Animazione Tween per farla "saltare" fuori
			var tween_x = drop.create_tween()
			tween_x.tween_property(drop, "global_position:x", end_pos.x, 0.4)
			
			var tween_y = drop.create_tween()
			var peak_y = min(start_pos.y, end_pos.y) - 25
			tween_y.tween_property(drop, "global_position:y", peak_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween_y.tween_property(drop, "global_position:y", end_pos.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
		is_talking = false
		if player_target != null and "can_move" in player_target:
			player_target.can_move = true
