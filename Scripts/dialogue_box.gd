extends CanvasLayer

# Percorso aggiornato: entra nella TextureRect, poi nel Panel, poi nella Label
@onready var text_label = $TextureRect/Panel/Label 
@onready var background = $TextureRect 

func _ready():
	hide() # Nascondiamo il box all'avvio

func show_message(text: String):
	text_label.text = text
	
	# Reset del testo (lo nascondiamo tutto all'inizio)
	text_label.visible_characters = 0
	
	# Mostriamo i pezzi grafici
	background.show()
	$TextureRect/Panel.show()
	text_label.show()
	show()
	
	# Creiamo l'effetto comparsa lettera per lettera
	var tween = get_tree().create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR)
