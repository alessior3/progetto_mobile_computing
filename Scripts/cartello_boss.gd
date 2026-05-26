extends Area2D

var player_in_range: bool = false
var current_player: Node2D = null

@export var messaggio: Array[String] = [
	"--- REGOLE DELLA PORTA DEL BOSS ---",
	"L'antica porta del boss è sigillata.",
	"Per aprirla, devi trovare 3 Gemme Speciali (Verde, Viola e Rossa) nascoste nei forzieri del dungeon.",
	"Una volta che le avrai tutte e tre nel tuo inventario, avvicinati alla porta e si aprirà automaticamente."
]

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body
		if body.has_node("Key"):
			body.get_node("Key").show()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").play("KeyPrompt")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		current_player = null
		if body.has_node("Key"):
			body.get_node("Key").hide()
		if body.has_node("KeyPrompt"):
			body.get_node("KeyPrompt").stop()

var is_talking: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_talking and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		is_talking = true
		var testo: Array[String] = [
			"--- ATTENZIONE INTRUSO ---",
			"Il potentissimo RE BYTE ha sigillato questa stanza.",
			"Ha nascosto 3 Gemme di Sicurezza nei meandri del dungeon.",
			"Trova la Gemma Verde, la Gemma Viola e la Gemma Rossa.",
			"Inseriscile nei 3 computer qui davanti per violare il sistema.",
			"Solo quando tutti i terminali diventeranno verdi...",
			"...il gigantesco cancello per l'arena finale si aprirà!"
		]
		DialogueManager.show_message(testo, "Cartello Elettronico")
		await DialogueManager.dialogue_finished
		is_talking = false
