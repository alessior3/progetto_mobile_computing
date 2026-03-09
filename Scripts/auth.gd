extends Node

# Segnali che useremo per dire al Menu se l'operazione è andata a buon fine
signal login_succeeded(local_id, id_token)
signal login_failed(error_message)
signal register_succeeded(local_id)
signal register_failed(error_message)

var api_key : String = ""
var config_file_path = "res://secret.cfg"

func _ready():
	# Appena il gioco si avvia, carica la chiave segreta
	load_api_key()

func load_api_key():
	var config = ConfigFile.new()
	var err = config.load(config_file_path)
	if err == OK:
		api_key = config.get_value("firebase", "api_key", "")
		print("Chiave Firebase caricata con successo!")
	else:
		print("ERRORE: Impossibile trovare il file secret.cfg")

# --- FUNZIONE REGISTRAZIONE ---
func register_user(email, password):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_register_request_completed.bind(http))
	
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + api_key
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"email": email, "password": password, "returnSecureToken": true})
	
	http.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_register_request_completed(result, response_code, headers, body, http_node):
	http_node.queue_free() # Eliminiamo il nodo HTTP per non sporcare la scena
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200:
		emit_signal("register_succeeded", json.get("localId", ""))
	else:
		var error_msg = _translate_error(json)
		emit_signal("register_failed", error_msg)

# --- FUNZIONE LOGIN ---
func login_user(email, password):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_request_completed.bind(http))
	
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + api_key
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"email": email, "password": password, "returnSecureToken": true})
	
	http.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_login_request_completed(result, response_code, headers, body, http_node):
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200:
		emit_signal("login_succeeded", json.get("localId", ""), json.get("idToken", ""))
	else:
		var error_msg = _translate_error(json)
		emit_signal("login_failed", error_msg)

# --- FUNZIONE ESCI ---
func logout():
	print("Utente disconnesso.")
	# Qui in futuro potremo cancellare i dati salvati locali, se necessario.

# --- TRADUTTORE DI ERRORI ---
func _translate_error(json) -> String:
	if json and json.has("error") and json["error"].has("message"):
		var msg = json["error"]["message"]
		if msg == "EMAIL_EXISTS": return "Questa email è già registrata!"
		if msg == "EMAIL_NOT_FOUND": return "Email non trovata. Devi prima registrarti."
		if msg == "INVALID_PASSWORD": return "Password errata!"
		if msg == "INVALID_LOGIN_CREDENTIALS": return "Email o Password errati."
		if msg.begins_with("WEAK_PASSWORD"): return "La password deve essere di almeno 6 caratteri."
		if msg == "INVALID_EMAIL": return "Formato email non valido."
		if msg == "MISSING_PASSWORD": return "Devi inserire una password."
		return "Errore sconosciuto: " + msg
	return "Errore di connessione a Internet."
