extends Area2D

@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D

func _ready():
	# All'inizio della battaglia i laser sono invisibili e innocui
	hide()
	monitoring = false

func attack():
	# 1. Rendiamo tutto visibile, senza trasparenze
	show()
	sprite.show()
	sprite.modulate = Color.WHITE 
	$BeamSound.play()
	# 2. Li allunghiamo per farli diventare raggi letali (puoi cambiare il 15)
	scale = Vector2(1, 15) 
	z_index = 50 
	
	# 3. Attiviamo l'hitbox per far prendere danno al giocatore
	monitoring = true 
	
	# 4. Facciamo partire l'animazione della luce
	if animation_player.has_animation("attack"):
		animation_player.play("attack")
	
	# 5. Quanto dura il laser? Qui sta a schermo per 1.5 secondi
	await get_tree().create_timer(1.5).timeout
	
	# 6. Fine dell'attacco: il laser si spegne e smette di fare danno
	hide()
	monitoring = false


func _on_body_entered(body):
	if body.is_in_group("Player") or body.is_in_group("player"):
		print("ZAP! Ora ti faccio danno per davvero!")
		
		# Calcoliamo la vita rimanente: vita attuale meno 1
		var vita_rimanente = Global.persistent_health - 30
		
		# Chiamiamo la funzione del player passandogli il nuovo valore
		body._on_damage_taken(vita_rimanente)
