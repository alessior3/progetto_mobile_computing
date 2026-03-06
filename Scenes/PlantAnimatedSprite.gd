extends AnimatedSprite2D

# Diamo un nome unico a questa classe per poterla referenziare facilmente.
class_name PlantAnimatedSprite

# Definiamo funzioni semplici che corrispondono ai nomi delle animazioni
# visibili nel pannello di image_8.png.

# Questa funzione fa partire l'animazione base quando la pianta è ferma.
func play_idle():
	# 'bomber_idle' sembra il nome corretto dall'immagine.
	play("bomber_idle")

# Questa funzione viene chiamata dallo script principale quando la pianta muore.
func play_death():
	play("death_animation")

# Questa funzione può essere utile se la pianta ha un'animazione quando subisce danno.
func play_hit():
	# Verifichiamo se l'animazione esiste prima di farla partire per evitare errori.
	if sprite_frames.has_animation("hit_animation"):
		play("hit_animation")
		# Piccolo trucco professionale: attendiamo che finisca 'hit' e torniamo subito 'idle'
		animation_finished.connect(_return_to_idle, CONNECT_ONE_SHOT)

func _return_to_idle():
	# Verifichiamo se siamo tornati vivi (utile se il segnale hit_finished collide con la morte)
	if is_inside_tree():
		play_idle()

# Aggiungiamo altre helper se necessario per le animazioni attack, going_up, going_down.
