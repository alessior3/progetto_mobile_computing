extends Resource

class_name InventoryItem

var stacks = 1

@export_enum("Hand", "Potions", "Food", "NotEquipable")
var slot_type : String = "NotEquipable"

@export var ground_collision_shape: RectangleShape2D
@export var name: String = ""
@export var texture: Texture2D
@export var side_texture: Texture2D
@export var max_stacks: int
@export var price: int
@export var is_weapon: bool = false
@export var damage: int = 1
