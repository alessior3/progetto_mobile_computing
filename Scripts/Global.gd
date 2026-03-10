extends Node

var player_pos : Vector2
var current_username = "Giocatore Sconosciuto"

var persistent_gold: int = 0
var persistent_items: Array[InventoryItem] = []

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
			"raccolti": collected_item_ids # Salvataggio lista nera
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
		return true
	return false
