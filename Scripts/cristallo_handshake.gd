extends CharacterBody2D

# Esponiamo le variabili nell'Inspector a destra per configurarle senza duplicare il codice
@export_enum("SYN", "SYN_ACK", "ACK") var tipo_pacchetto: String = "SYN"
@export var porta_boss: StaticBody2D # Trascineremo la porta qui

func _ready():
	# Scrive in automatico il tipo di pacchetto sulla Label sopra al cristallo
	if has_node("Label"):
		$Label.text = tipo_pacchetto

# Questa funzione viene chiamata in automatico dal Player quando sferra il colpo!
func apply_damage(_amount: int):
	print("Giocatore ha colpito il cristallo: ", tipo_pacchetto)
	
	if porta_boss:
		porta_boss.ricevi_pacchetto(tipo_pacchetto)
	else:
		print("ERRORE: Non hai collegato la PortaBoss a questo cristallo nell'Inspector!")
