extends Area2D
class_name Dungeon1Entrance

# Puoi cambiare la scena di destinazione comodamente dall'Inspector
@export var destination_scene: String = "res://Scenes/dungeon_1.tscn"

var player_in_range: bool = false
var current_player: CharacterBody2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print("Qualcosa è entrato nell'area: ", body.name) # AGGIUNGI QUESTA RIGA
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		
		# Mostra l'animazione del tasto sul Player
		if body.has_node("Key"): body.get_node("Key").show()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		
		# Nasconde il tasto quando ti allontani
		if body.has_node("Key"): body.get_node("Key").hide()
		if body.has_node("KeyPrompt"): body.get_node("KeyPrompt").stop()

func _input(event: InputEvent) -> void:
	# Se il giocatore è nell'area e preme il tasto di interazione
	if player_in_range and event.is_action_pressed("interact"):
		enter_dungeon()

func enter_dungeon() -> void:
	print("DEBUG (Mondo): Salvataggio stato in corso...")
	
	# 1. SALVATAGGIO: Scrive su disco l'oro, l'inventario e gli ID degli oggetti raccolti
	Global.save_game() 
	
	# 2. PULIZIA VISIVA: Nascondiamo il prompt prima di cambiare scena per evitare che rimanga "incastrato"
	if current_player and current_player.has_node("Key"): 
		current_player.get_node("Key").hide()
	
	print("DEBUG (Mondo): Caricamento scena: ", destination_scene)
	
	# 3. TRANSIZIONE: Passiamo al dungeon
	get_tree().change_scene_to_file(destination_scene)
