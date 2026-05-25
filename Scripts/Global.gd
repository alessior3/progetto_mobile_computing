extends Node

var player_pos : Vector2
var current_username = "Giocatore Sconosciuto"
# Variabile per ricordare la vita tra una scena e l'altra
var persistent_health: int = 100
var persistent_gold: int = 0
var persistent_items: Array[InventoryItem] = []
var is_first_start: bool = true

# ID degli oggetti già raccolti per non farli riapparire
var collected_item_ids: Array[String] = [] 

# Slot equipaggiamento persistenti
var persistent_hand: InventoryItem = null
var persistent_potions: InventoryItem = null
var persistent_food: InventoryItem = null
# La direzione in cui guarderà il player al caricamento della scena
var player_facing_dir: String = "down"
var save_path = "user://savegame.save"
# Dizionario che ricorderà cosa c'è dentro ogni singola cassa del gioco
var chests_data: Dictionary = {}
var from_percorso: bool = false
var from_grotta_to_percorso: bool = false
var from_house3_to_percorso: bool = false
var from_villaggio2_to_percorso1: bool = false
var from_percorso1_to_villaggio2: bool = false
var from_villaggio2_to_percorso2: bool = false
var from_percorso2_to_villaggio2: bool = false
var from_percorso2_to_villaggio3: bool = false
var from_villaggio3_to_percorso2: bool = false
var from_grotta2_to_dungeon2: bool = false

var last_world_scene: String = "res://Scenes/world.tscn"
var has_received_floppy: bool = false
var has_tried_cave: bool = false
var has_paid_treasurer: bool = false
var has_hermit_pass: bool = false
var talked_to_npc1: bool = false
var talked_to_npc2: bool = false
var talked_to_npc3: bool = false
var talked_to_npc_vecchio: bool = false
var talked_to_npc_vecchio2: bool = false
var talked_to_npc_floppy: bool = false
var talked_to_npc_villaggio2: bool = false
var talked_to_npc_villaggio2_house: bool = false
var talked_to_npc_villaggio3: bool = false
var talked_to_npc_villaggio4: bool = false
var talked_to_npc_prete2: bool = false

var quest_accendino_started: bool = false
var has_accendino: bool = false
var quest_accendino_completed: bool = false

var google_web_client_id = "779309651323-ntcj6cp529p6r01vt5f2im0jdpdt9266.apps.googleusercontent.com"

func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var data = {
			"nome": current_username,
			"posizione": player_pos,
			"oro": persistent_gold,
			"oggetti": persistent_items,
			"hand": persistent_hand,
			"potions": persistent_potions,
			"food": persistent_food,
			"raccolti": collected_item_ids, # Salvataggio lista nera
			"has_received_floppy": has_received_floppy,
			"has_tried_cave": has_tried_cave,
			"has_paid_treasurer": has_paid_treasurer,
			"has_hermit_pass": has_hermit_pass,
			"talked_to_npc1": talked_to_npc1,
			"talked_to_npc2": talked_to_npc2,
			"talked_to_npc3": talked_to_npc3,
			"talked_to_npc_vecchio": talked_to_npc_vecchio,
			"talked_to_npc_vecchio2": talked_to_npc_vecchio2,
			"talked_to_npc_floppy": talked_to_npc_floppy,
			"talked_to_npc_villaggio2": talked_to_npc_villaggio2,
			"talked_to_npc_villaggio2_house": talked_to_npc_villaggio2_house,
			"talked_to_npc_villaggio3": talked_to_npc_villaggio3,
			"talked_to_npc_villaggio4": talked_to_npc_villaggio4,
			"talked_to_npc_prete2": talked_to_npc_prete2,
			"quest_accendino_started": quest_accendino_started,
			"has_accendino": has_accendino,
			"quest_accendino_completed": quest_accendino_completed
		}
		file.store_var(data)
		file.close()

func load_game() -> bool:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		# Usiamo .get() con valori di default per evitare crash se mancano chiavi
		current_username = data.get("nome", "Giocatore Sconosciuto")
		player_pos = data.get("posizione", Vector2.ZERO)
		persistent_gold = data.get("oro", 0)
		persistent_items = data.get("oggetti", [])
		persistent_hand = data.get("hand", null)
		persistent_potions = data.get("potions", null)
		persistent_food = data.get("food", null)
		collected_item_ids = data.get("raccolti", []) 
		has_received_floppy = data.get("has_received_floppy", false)
		has_tried_cave = data.get("has_tried_cave", false)
		has_paid_treasurer = data.get("has_paid_treasurer", false)
		has_hermit_pass = data.get("has_hermit_pass", false)
		talked_to_npc1 = data.get("talked_to_npc1", false)
		talked_to_npc2 = data.get("talked_to_npc2", false)
		talked_to_npc3 = data.get("talked_to_npc3", false)
		talked_to_npc_vecchio = data.get("talked_to_npc_vecchio", false)
		talked_to_npc_vecchio2 = data.get("talked_to_npc_vecchio2", false)
		talked_to_npc_floppy = data.get("talked_to_npc_floppy", false)
		talked_to_npc_villaggio2 = data.get("talked_to_npc_villaggio2", false)
		talked_to_npc_villaggio2_house = data.get("talked_to_npc_villaggio2_house", false)
		talked_to_npc_villaggio3 = data.get("talked_to_npc_villaggio3", false)
		talked_to_npc_villaggio4 = data.get("talked_to_npc_villaggio4", false)
		talked_to_npc_prete2 = data.get("talked_to_npc_prete2", false)
		
		quest_accendino_started = data.get("quest_accendino_started", false)
		has_accendino = data.get("has_accendino", false)
		quest_accendino_completed = data.get("quest_accendino_completed", false)
		return true
	return false

# --- NUOVA FUNZIONE PER QUANDO IL PLAYER MUORE ---
func reset_inventory_and_gold():
	persistent_gold = 0
	persistent_items.clear()
	persistent_hand = null
	persistent_potions = null
	persistent_food = null
	# Non svuotiamo collected_item_ids, altrimenti gli oggetti nel mondo respawnano!
