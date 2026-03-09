extends Node

var api_key : String = ""
var database_url : String = ""
var config_file_path = "res://secret.cfg"

# Variabili per gestire il caricamento della posizione
var is_loading_game: bool = false
var loaded_position: Vector2 = Vector2.ZERO

func _ready():
	load_config()

func load_config():
	var config = ConfigFile.new()
	var err = config.load(config_file_path)
	if err == OK:
		api_key = config.get_value("firebase", "api_key", "")
		database_url = config.get_value("firebase", "database_url", "")
	else:
		print("Errore caricamento secret.cfg")

# --- SALVATAGGIO CLOUD ---
func save_game():
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		print("ERRORE: Giocatore non trovato!")
		return
	
	# Verifichiamo se l'email è stata salvata correttamente nel Global
	if Global.current_username == "":
		print("ERRORE: Email utente vuota nel Global!")
		return

	var user_id = Global.current_username.replace(".", "_")
	
	var data = {
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
		"saved_scene": get_tree().current_scene.scene_file_path
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	
	# --- RIGA DA AGGIUNGERE PER DEBUG ---
	var url = database_url + "users/" + user_id + ".json"
	print("DEBUG - Indirizzo finale: ", url) 
	# ------------------------------------

	var body = JSON.stringify(data)
	var err = http.request(url, [], HTTPClient.METHOD_PUT, body)
	
	if err != OK:
		print("ERRORE nell'invio della richiesta HTTP!")
	else:
		print("Richiesta inviata correttamente... controlla il database!")

# --- CARICAMENTO CLOUD ---
func load_game():
	print("--- TASTO CARICA PREMUTO: Inizio il recupero dati dal Cloud ---")
	
	if Global.current_username == "":
		print("ERRORE: Non sei loggato! L'email è vuota.")
		return false

	var user_id = Global.current_username.replace(".", "_")
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_load_request_completed)
	
	var url = database_url + "users/" + user_id + ".json"
	print("DEBUG Caricamento - URL: ", url)
	
	http.request(url, [], HTTPClient.METHOD_GET)
	return true	

func _on_load_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	# Controlliamo che json sia un Dizionario e che abbia le chiavi che ci servono
	if json is Dictionary and json.has("player_x") and json.has("player_y"):
		loaded_position = Vector2(json["player_x"], json["player_y"])
		is_loading_game = true
		
		if json.has("saved_scene"):
			get_tree().change_scene_to_file(json["saved_scene"])
			print("Dati scaricati dal Cloud con successo!")
	else:
		print("ATTENZIONE: Nessun dato trovato per questo utente. Hai salvato almeno una volta?")
		# Possiamo mostrare l'errore sulla feedback_label se vogliamo
