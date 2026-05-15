extends "res://Scripts/arena_door.gd"

# Questa porta si apre automaticamente se il player ha pagato il Tesoriere
func _ready():
	super._ready() # Chiama il ready della porta base
	
	# Se il player ha già pagato in passato, la porta deve nascere aperta
	if Global.has_paid_treasurer:
		open_door()
	else:
		close_door()

func _process(_delta):
	# Se il player paga mentre è nella stanza, la porta si apre istantaneamente
	if not is_closed == false and Global.has_paid_treasurer:
		open_door()
