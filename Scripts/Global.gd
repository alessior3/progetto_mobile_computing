# Global.gd
extends Node

var player_pos : Vector2
var current_username = "Giocatore Sconosciuto"

var persistent_gold: int = 0
var persistent_items: Array[InventoryItem] = []

# NUOVE VARIABILI PER GLI SLOT
var persistent_hand: InventoryItem = null
var persistent_potions: InventoryItem = null
var persistent_food: InventoryItem = null

var save_path = "user://savegame.save"

func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var data = {
			"nome": current_username,
			"posizione": player_pos,
			"oro": persistent_gold,
			"oggetti": persistent_items,
			# Salviamo anche gli slot equipaggiati
			"hand": persistent_hand,
			"potions": persistent_potions,
			"food": persistent_food
		}
		file.store_var(data)
		file.close()

func load_game() -> bool:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = file.get_var()
		file.close()
		
		current_username = data["nome"]
		player_pos = data["posizione"]
		persistent_gold = data.get("oro", 0)
		persistent_items = data.get("oggetti", [])
		
		# Carichiamo gli slot
		persistent_hand = data.get("hand", null)
		persistent_potions = data.get("potions", null)
		persistent_food = data.get("food", null)
		return true
	return false
