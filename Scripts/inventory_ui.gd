extends CanvasLayer
class_name InventoryUI

# RIFERIMENTI
@onready var grid_container: GridContainer = %GridContainer
const INVENTORY_SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")

# Questo deve essere l'inventario del Player (assegnato dall'inspector o via codice)
@export var inventory: Inventory 

@export var size: int = 16
@export var columns: int = 4

func _ready() -> void:    
	print("DEBUG (UI): Inizializzazione InventoryUI. Colonne: ", columns)
	grid_container.columns = columns
	
	# Creiamo i quadratini vuoti all'inizio
	for i in size:
		var inventory_slot = INVENTORY_SLOT_SCENE.instantiate()
		grid_container.add_child(inventory_slot)
	
	# Nascondiamo l'UI all'avvio
	hide()
	print("DEBUG (UI): Generati correttamente ", grid_container.get_child_count(), " slot.")

func toggle():
	visible = !visible
	# Se apriamo l'inventario, aggiorniamo subito i dati
	if visible and inventory:
		update_slots(inventory.items)

# FUNZIONE RIFATTORIZZATA
func update_slots(items_list: Array[InventoryItem]):
	var slots = grid_container.get_children()
	
	for i in range(slots.size()):
		var slot = slots[i]
		
		# Verifichiamo se c'è un oggetto per questo slot nell'array items_list
		if i < items_list.size():
			var current_item = items_list[i]
			
			# Usiamo i nomi delle funzioni che abbiamo deciso per InventorySlot
			slot.add_item(current_item)
			
			# Connettiamo il segnale di click (slot_clicked)
			if not slot.slot_clicked.is_connected(_on_slot_item_clicked):
				slot.slot_clicked.connect(_on_slot_item_clicked)
		else:
			# Se lo slot è vuoto, lo puliamo
			slot.add_item(null)

# Questa funzione riceve l'item dallo slot e lo manda allo script Inventory del player
func _on_slot_item_clicked(item: InventoryItem):
	if inventory:
		inventory._on_slot_item_clicked(item)
