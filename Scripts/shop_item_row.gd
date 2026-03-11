extends Button
class_name ShopItemRow

# Questo segnale avviserà il pannello di destra quando clicchi questa riga
signal item_clicked(item: InventoryItem)

var current_item: InventoryItem

# Assicurati che i percorsi corrispondano ai nomi che hai dato ai nodi!
@onready var item_icon: TextureRect = $HBoxContainer/ItemIcon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var price_label: Label = $HBoxContainer/PriceLabel
@onready var selection_highlight: ColorRect = $SelectionHighlight

func _ready() -> void:
	# Colleghiamo automaticamente il click del bottone a una nostra funzione
	pressed.connect(_on_row_pressed)

# Questa funzione viene chiamata dallo shop per riempire la riga con i dati
func setup(item: InventoryItem) -> void:
	current_item = item
	
	if item.texture:
		item_icon.texture = item.texture
		
	name_label.text = item.name
	# Formattazione pulita del prezzo
	price_label.text = str(item.price * item.stacks) + " Gold"

func _on_row_pressed() -> void:
	# Quando clicchi la riga, "urla" al pannello principale quale oggetto hai scelto
	item_clicked.emit(current_item)
	
func set_highlight(active: bool) -> void:
	selection_highlight.visible = active # Accendiamo/spegniamo il rettangolo
