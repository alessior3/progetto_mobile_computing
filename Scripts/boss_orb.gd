extends Area2D

# Valore esatto del tutorial
var speed: float = 200.0 
var direction: Vector2 = Vector2.ZERO # Aggiungiamo la direzione vuota (la deciderà il boss)
var damage: int = 1
var is_exploding: bool = false # Per bloccare la sfera quando sbatte

@onready var anim_player = $AnimationPlayer

func _ready():
	top_level = true
	# Distrugge la sfera dopo 4 secondi se per caso viaggia nel vuoto all'infinito
	await get_tree().create_timer(4.0).timeout
	if not is_exploding:
		queue_free()

func _process(delta):
	# Usa la "direction" invece di Vector2.DOWN, e si muove SOLO se non sta esplodendo
	if direction != Vector2.ZERO and not is_exploding:
		global_position += direction * speed * delta


func _on_body_entered(body):
	# Anche qui controlliamo il gruppo!
	if (body.is_in_group("Player") or body.is_in_group("player")) and not is_exploding:
		is_exploding = true
		
		var vita_rimanente = Global.persistent_health - 50
		body._on_damage_taken(vita_rimanente)
		$HitSound.play()
		
		if anim_player:
			anim_player.play("explode")
			await anim_player.animation_finished 
		
		queue_free()
