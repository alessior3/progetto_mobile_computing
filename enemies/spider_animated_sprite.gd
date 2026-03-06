extends AnimatedSprite2D

# 1. Cambiamo il nome per non fare a pugni con il fantasma!
class_name SpiderAnimatedSprite2D

# 2. Funzione per camminare (chiamata in automatico dallo script di base)
func play_movement_animation(direction: Vector2):
	# Controlliamo la direzione sull'asse X per girare lo sprite
	if direction.x < 0:
		flip_h = true  # Se va a sinistra, specchiamo l'immagine
	elif direction.x > 0:
		flip_h = false # Se va a destra, la teniamo normale
		
	# Facciamo partire l'animazione di corsa
	play("run")

# 3. Funzione per stare fermo
func play_idle_animation():
	play("idle")

# 4. Funzione per quando subisce danno (la collegheremo dopo)
func play_hit_animation():
	play("hit")
