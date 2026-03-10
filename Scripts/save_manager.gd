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

# --- FUNZIONI DI TRADUZIONE INVENTARIO ---

# Converte le Resource in percorsi testuali per Firebase
func serialize_inventory(items: Array[InventoryItem]) -> Array:
	var serialized = []
	for item in items:
		if item:
			serialized.append(item.resource_path)
	return serialized

# Converte i percorsi testuali da Firebase di nuovo in Resource
func deserialize_inventory(paths: Array) -> Array[InventoryItem]:
	var deserialized: Array[InventoryItem] = []
	for path in paths:
		if path != "" and ResourceLoader.exists(path):
			var item = load(path) as InventoryItem
			if item:
				deserialized.append(item)
	return deserialized

# Converte un singolo oggetto equipaggiato
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
	
	# Pacchetto dati completo da spedire a Firebase
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
	http.request_completed.connect(_on_save_completed)
	
	var url = database_url + "users/" + user_id + ".json"
	var body = JSON.stringify(data)
	var err = http.request(url, [], HTTPClient.METHOD_PUT, body)
	
	if err != OK:
		print("ERRORE nell'invio della richiesta HTTP!")
	else:
		print("Invio dati salvataggio in corso...")

func _on_save_completed(result, response_code, headers, body):
	print("Salvataggio completato! Codice:", response_code)

# --- CARICAMENTO CLOUD ---
func load_game():
	print("--- Inizio recupero dati dal Cloud ---")
	
	if Global.current_username == "":
		print("ERRORE: Non sei loggato!")
		return false

	var user_id = Global.current_username.replace(".", "_")
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_load_request_completed)
	
	var url = database_url + "users/" + user_id + ".json"
	http.request(url, [], HTTPClient.METHOD_GET)
	return true    

func _on_load_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json is Dictionary and json.has("player_x") and json.has("player_y"):
		# 1. Ripristino Posizione
		loaded_position = Vector2(json["player_x"], json["player_y"])
		is_loading_game = true
		
		# 2. Ripristino Oro
		Global.persistent_gold = json.get("oro", 0)
		
		# 3. Ripristino Inventario (Zaino)
		var oggetti_zaino_paths = json.get("oggetti_zaino", [])
		Global.persistent_items = deserialize_inventory(oggetti_zaino_paths)
		
		# 4. Ripristino Equipaggiamento
		Global.persistent_hand = deserialize_item(json.get("mano", ""))
		Global.persistent_potions = deserialize_item(json.get("pozioni", ""))
		Global.persistent_food = deserialize_item(json.get("cibo", ""))
		
		
		# 5. Ripristino Oggetti raccolti (per non farli ricomparire)
		var raccolti_temporanei = json.get("raccolti", [])
		Global.collected_item_ids.clear() # Svuotiamo quello vecchio
		for id_raccolto in raccolti_temporanei:
			Global.collected_item_ids.append(str(id_raccolto)) # Lo forziamo a essere una Stringa
		
		# 6. Caricamento Scena
		if json.has("saved_scene"):
			get_tree().change_scene_to_file(json["saved_scene"])
			print("Dati Cloud scaricati e ripristinati con successo!")
	else:
		print("ATTENZIONE: Nessun dato trovato per questo utente.")
