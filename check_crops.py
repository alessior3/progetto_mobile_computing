import os
import re

def check_dir(base_dir, prefix):
    for root, dirs, files in os.walk(base_dir):
        for f in files:
            if f.endswith("sprite.tres") or "sprite" in f.lower() and f.endswith(".tres"):
                path = os.path.join(root, f)
                with open(path, 'r') as file:
                    content = file.read()
                    match = re.search(r'path="res://Sunnyside_World_ASSET_PACK_V2.1/Sunnyside_World_Assets/Elements/Crops/([^"]+)"', content)
                    if match:
                        print(f"{prefix} {f}: {match.group(1)}")
                    else:
                        print(f"{prefix} {f}: NO MATCH")

check_dir("Resources", "ALL")
