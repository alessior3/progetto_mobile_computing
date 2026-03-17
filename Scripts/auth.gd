extends Node

# --- SEGNALI ---
signal login_succeeded(local_id, id_token)
signal login_failed(error_message)
signal register_succeeded(local_id)
signal register_failed(error_message)

# NUOVO SEGNALE PER GOOGLE
signal google_login_succeeded(email)

var api_key : String = ""
var config_file_path = "res://secret.cfg"

func _ready():
	load_api_key()

func load_api_key():
	var config = ConfigFile.new()
	var err = config.load(config_file_path)
	if err == OK:
		# strip_edges() rimuove spazi vuoti o "a capo" invisibili che distruggono le richieste HTTP!
		api_key = config.get_value("firebase", "api_key", "").strip_edges()
		print("Chiave Firebase caricata con successo! Lunghezza: ", api_key.length())
	else:
		print("ERRORE: Impossibile trovare il file secret.cfg")

# --- FUNZIONE REGISTRAZIONE CLASSICA ---
func register_user(email, password):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_register_request_completed.bind(http))
	
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + api_key
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"email": email, "password": password, "returnSecureToken": true})
	
	http.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_register_request_completed(result, response_code, headers, body, http_node):
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200:
		emit_signal("register_succeeded", json.get("localId", ""))
	else:
		var error_msg = _translate_error(json)
		emit_signal("register_failed", error_msg)

# --- FUNZIONE LOGIN CLASSICO (VERSIONE DEBUG) ---
func login_user(email, password):
	print("1. Preparo la richiesta HTTP per il login...")
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_request_completed.bind(http))
	
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + api_key
	print("2. URL pronto (lunghezza chiave usata: ", api_key.length(), ")")
	
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({"email": email, "password": password, "returnSecureToken": true})
	
	# Catturiamo il risultato istantaneo della richiesta
	var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if err != OK:
		print("ERRORE CRITICO: Godot si rifiuta di inviare la richiesta! Codice errore: ", err)
		emit_signal("login_failed", "Errore interno: impossibile connettersi.")
	else:
		print("3. Richiesta partita verso Firebase! In attesa...")

func _on_login_request_completed(result, response_code, headers, body, http_node):
	print("4. Risposta ricevuta da Firebase! Codice HTTP: ", response_code)
	http_node.queue_free()
	
	var response_string = body.get_string_from_utf8()
	print("Contenuto risposta: ", response_string)
	
	# Controllo di sicurezza nel caso Firebase non risponda con un JSON
	var json = {}
	if response_string != "":
		json = JSON.parse_string(response_string)
		if typeof(json) != TYPE_DICTIONARY:
			json = {}
			
	if response_code == 200:
		print("5. Login Perfetto!")
		emit_signal("login_succeeded", json.get("localId", ""), json.get("idToken", ""))
	else:
		print("5. Errore da Firebase!")
		var error_msg = _translate_error(json)
		emit_signal("login_failed", error_msg)

# --- NUOVA FUNZIONE: LOGIN CON GOOGLE (NATIVO ANDROID) ---
func login_with_google(google_id_token: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_google_firebase_completed.bind(http))
	
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=" + api_key
	var headers = ["Content-Type: application/json"]
	
	# Formattazione speciale richiesta da Firebase
	var post_body = "id_token=" + google_id_token + "&providerId=google.com"
	var body_data = {
		"postBody": post_body,
		"requestUri": "http://localhost",
		"returnIdpCredential": true,
		"returnSecureToken": true
	}
	
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body_data))

func _on_google_firebase_completed(result, response_code, headers, body, http_node):
	http_node.queue_free()
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if response_code == 200:
		var google_email = json.get("email", "GiocatoreGoogle")
		emit_signal("google_login_succeeded", google_email)
	else:
		var error_msg = _translate_error(json)
		emit_signal("login_failed", "Errore Google-Firebase: " + error_msg)

# --- FUNZIONE ESCI ---
func logout():
	print("Utente disconnesso.")

# --- TRADUTTORE DI ERRORI ---
func _translate_error(json) -> String:
	if typeof(json) == TYPE_DICTIONARY and json.has("error") and json["error"].has("message"):
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
