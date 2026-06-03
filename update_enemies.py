import os
import re

files = [
    "Scenes/spider.tscn", "Scenes/phantom.tscn", "Scenes/pink_slime.tscn", 
    "Scenes/pink_bat.tscn", "Scenes/enemy.tscn", "Scenes/beast.tscn", "Scenes/red_gladiator.tscn",
    "Scripts/spider.gd", "Scripts/phantom.gd", "Scripts/pink_slime.gd", 
    "Scripts/pink_bat.gd", "Scripts/enemy.gd", "Scripts/beast.gd", "Scripts/red_gladiator.gd"
]

for f in files:
    if not os.path.exists(f):
        continue
    
    with open(f, 'r') as file:
        content = file.read()
    
    modified = False
    
    # 1. Update health
    if f.endswith('.gd'):
        if "beast.gd" in f or "red_gladiator.gd" in f or "enemy.gd" in f:
            content = re.sub(r'@export var health: int = 100', r'@export var health: int = 70', content)
            content = re.sub(r'@export var max_health: int = 100', r'@export var max_health: int = 70', content)
            modified = True
        else:
            content = re.sub(r'@export var health: int = 50', r'@export var health: int = 30', content)
            modified = True

        # 2. Add Knockback variables and function
        if "is_knocked_back" not in content:
            knockback_code = """
var is_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

func apply_knockback(direction: Vector2):
\tis_knocked_back = true
\tknockback_velocity = direction * 300.0
\tawait get_tree().create_timer(0.2).timeout
\tif get_tree() != null:
\t\tis_knocked_back = false
"""
            # Insert before _physics_process or _ready
            if "func _ready()" in content:
                content = content.replace("func _ready()", knockback_code + "\nfunc _ready()")
            else:
                content = content.replace("func _physics_process", knockback_code + "\nfunc _physics_process")
            modified = True
            
        # 3. Add knockback logic to _physics_process
        if "knockback_velocity = knockback_velocity.move_toward" not in content:
            physics_logic = """
\tif is_knocked_back:
\t\tvelocity = knockback_velocity
\t\tmove_and_slide()
\t\tknockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1500 * delta)
\t\treturn
"""
            # Find func _physics_process(delta...):
            match = re.search(r'func _physics_process\(delta(.*?)\)(.*?):', content)
            if match:
                sig = match.group(0)
                content = content.replace(sig, sig + physics_logic)
                modified = True

    elif f.endswith('.tscn'):
        # Update export overrides in scene files if any
        if "beast.tscn" in f or "red_gladiator.tscn" in f or "enemy.tscn" in f:
            content = re.sub(r'health = 100', r'health = 70', content)
            content = re.sub(r'max_health = 100', r'max_health = 70', content)
        else:
            content = re.sub(r'health = 50', r'health = 30', content)
        modified = True

    if modified:
        with open(f, 'w') as file:
            file.write(content)
        print(f"Updated {f}")

