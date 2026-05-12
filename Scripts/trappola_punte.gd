extends Node2D

@export var danno_trappola: int = 10 

# La collisione si attiva e si disattiva da sola con l'animazione!
# Quindi se questo segnale scatta, significa che le punte sono FUORI.
func _on_area_danno_body_entered(body: Node2D) -> void:
	
	if body.name == "player" or body.name == "Player" or body.is_in_group("player"):
		
		# Facciamo subito danno!
		if body.has_method("apply_damage"):
			body.apply_damage(danno_trappola)
			print("Ahi! Le punte hanno fatto ", danno_trappola, " danni al player!")
