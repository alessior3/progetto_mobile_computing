extends Resource
class_name InventoryItem

var stacks = 1

@export var item_id: String = "" # L'ID interno per il terreno
@export_enum("Hand", "Potions", "Food", "NotEquipable")
var slot_type : String = "NotEquipable"

@export var ground_collision_shape: RectangleShape2D
@export var name: String = ""
@export var texture: Texture2D
@export var side_texture: Texture2D
@export var max_stacks: int
@export var price: int

@export_group("Combattimento")
@export var is_weapon: bool = false
@export var damage: int = 1

@export_group("Effetti")
@export var is_consumable: bool = false
@export var heal_amount: int = 0
@export var buff_type: String = "nessuno"
@export var buff_value: int = 0
@export var buff_duration: float = 0.0
