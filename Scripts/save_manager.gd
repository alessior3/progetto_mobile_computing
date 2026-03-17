extends Node

# Segnale per avvisare il menu di come è andato il caricamento
signal load_response(success, message)

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
		# Rimuoviamo gli spazi invisibili per evitare crash su Android
		api_key = config.get_value("firebase", "api_key", "").strip_edges()
		database_url = config.get_value("firebase", "database_url", "").strip_edges()
		
		# Sicurezza extra: l'URL deve finire sempre con la barra "/"
		if database_url != "" and not database_url.ends_with("/"):
			database_url += "/"
	else:
		print("Errore caricamento secret.cfg")

# --- FUNZIONI DI TRADUZIONE INVENTARIO ---

func serialize_inventory(items: Array[InventoryItem]) -> Array:
	var serialized = []
	for item in items:
		if item:
			serialized.append(item.resource_path)
	return serialized

func deserialize_inventory(paths: Array) -> Array[InventoryItem]:
	var deserialized: Array[InventoryItem] = []
	for path in paths:
		if path != "" and ResourceLoader.exists(path):
			var item = load(path) as InventoryItem
			if item:
				deserialized.append(item)
	return deserialized

func serialize_item(item: InventoryItem) -> String:
	return item.resource_path if item else ""

func deserialize_item(path: String) -> InventoryItem:
	if path != "" and ResourceLoader.exists(path):
		return load(path) as InventoryItem
	return null

# --- SALVATAGGIO CLOUD ---
func save_game():
	var player = get_tree().get_first_node_in_group("player")
	if not player: 
		print("ERRORE: Giocatore non trovato!")
		return
	
	if Global.current_username == "":
		print("ERRORE: Email utente vuota nel Global!")
		return

	var user_id = Global.current_username.replace(".", "_")
	
	var data = {
		"player_x": player.global_position.x,
		"player_y": player.global_position.y,
		"saved_scene": get_tree().current_scene.scene_file_path,
		"oro": Global.persistent_gold,
		"oggetti_zaino": serialize_inventory(Global.persistent_items),
		"mano": serialize_item(Global.persistent_hand),
		"pozioni": serialize_item(Global.persistent_potions),
		"cibo": serialize_item(Global.persistent_food),
		"raccolti": Global.collected_item_ids
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	# Leghiamo il nodo HTTP alla funzione per poterlo eliminare dopo
	http.request_completed.connect(_on_save_completed.bind(http))
	
	var url = database_url + "users/" + user_id + ".json"
	var body = JSON.stringify(data)
	
	# Usiamo PackedStringArray, richiesto da Android
	var headers = PackedStringArray(["Content-Type: application/json"])
	var err = http.request(url, headers, HTTPClient.METHOD_PUT, body)
	
	if err != OK:
		print("ERRORE nell'invio della richiesta HTTP!")
		http.queue_free()

func _on_save_completed(result, response_code, headers, body, http_node):
	http_node.queue_free() # Eliminiamo il nodo fantasma per non intasare la memoria
	print("Salvataggio completato! Codice:", response_code)

# --- CARICAMENTO CLOUD ---
func load_game():
	print("--- Inizio recupero dati dal Cloud ---")
	
	if Global.current_username == "":
		emit_signal("load_response", false, "ERRORE: Non sei loggato!")
		return false

	var user_id = Global.current_username.replace(".", "_")
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(_on_load_request_completed.bind(http))
	
	var url = database_url + "users/" + user_id + ".json"
	var headers = PackedStringArray()
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	
	if err != OK:
		emit_signal("load_response", false, "ERRORE di connessione HTTP!")
		http.queue_free()
		return false
		
	return true    

func _on_load_request_completed(result, response_code, headers, body, http_node):
	http_node.queue_free() # Pulizia!
	
	var body_string = body.get_string_from_utf8()
	
	# Se l'utente non ha mai salvato, Firebase restituisce "null"
	if body_string == "" or body_string == "null":
		emit_signal("load_response", false, "Nessun salvataggio trovato!")
		return
		
	var json = JSON.parse_string(body_string)
	
	if typeof(json) == TYPE_DICTIONARY and json.has("player_x") and json.has("player_y"):
		loaded_position = Vector2(json["player_x"], json["player_y"])
		is_loading_game = true
		Global.persistent_gold = json.get("oro", 0)
		
		var oggetti_zaino_paths = json.get("oggetti_zaino", [])
		Global.persistent_items = deserialize_inventory(oggetti_zaino_paths)
		
		Global.persistent_hand = deserialize_item(json.get("mano", ""))
		Global.persistent_potions = deserialize_item(json.get("pozioni", ""))
		Global.persistent_food = deserialize_item(json.get("cibo", ""))
		
		var raccolti_temporanei = json.get("raccolti", [])
		Global.collected_item_ids.clear() 
		for id_raccolto in raccolti_temporanei:
			Global.collected_item_ids.append(str(id_raccolto)) 
		
		if json.has("saved_scene"):
			emit_signal("load_response", true, "Dati caricati! Avvio in corso...")
			get_tree().change_scene_to_file(json["saved_scene"])
	else:
		emit_signal("load_response", false, "I dati salvati sono corrotti!")
