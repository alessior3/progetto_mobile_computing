extends Area2D

# Valore esatto del tutorial
var speed: float = 200.0 

func _process(delta):
	# Direzione verso il basso (Vector2.DOWN è 0, 1)
	position += Vector2.DOWN * speed * delta


func _on_body_entered(body):
	if body.name == "Player": # O come si chiama il tuo nodo giocatore
		queue_free()
