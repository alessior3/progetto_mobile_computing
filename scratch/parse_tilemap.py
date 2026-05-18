import base64
import struct

# The base64 string for tile_map_data from oggetti layer in inside_house3.tscn
# PackData string inside tscn is base64 encoded when viewed in text format sometimes?
# Wait! In .tscn, PackedByteArray is written as PackedByteArray("...") where the contents inside "..." is base64 encoded!
# Let's check if it is base64 encoded.
# Let's see: "AAD7////AgAKAAEAAAD7/wAAAgAKAAIAAAD/////AgALAAUAAAD8/wAAAgABAAUAAAD9/wAAAgACAAUAAAABAAcAAgAIAAEAAAABAAgAAgAIAAIAAAACAAcAAgAJAAEAAAACAAgAAgAJAAIAAAD7/wQAAgAIAAEAAAD7/wUAAgAIAAIAAAD8/wQAAgAJAAEAAAD8/wUAAgAJAAIAAAD9/wMAAgAIAAEAAAD9/wQAAgAIAAIAAAD+/wMAAgAJAAEAAAD+/wQAAgAJAAIAAAABAAUAAgAIAAEAAAABAAYAAgAIAAIAAAACAAUAAgAJAAEAAAACAAYAAgAJAAIAAAACAP//AgAIAAEAAAACAAAAAgAIAAIAAAADAP//AgAJAAEAAAADAAAAAgAJAAIAAAAAAP//AgAIAAEAAAAAAAAAAgAIAAIAAAABAP//AgAJAAEAAAABAAAAAgAJAAIAAAA="

data_b64 = "AAD7////AgAKAAEAAAD7/wAAAgAKAAIAAAD/////AgALAAUAAAD8/wAAAgABAAUAAAD9/wAAAgACAAUAAAABAAcAAgAIAAEAAAABAAgAAgAIAAIAAAACAAcAAgAJAAEAAAACAAgAAgAJAAIAAAD7/wQAAgAIAAEAAAD7/wUAAgAIAAIAAAD8/wQAAgAJAAEAAAD8/wUAAgAJAAIAAAD9/wMAAgAIAAEAAAD9/wQAAgAIAAIAAAD+/wMAAgAJAAEAAAD+/wQAAgAJAAIAAAABAAUAAgAIAAEAAAABAAYAAgAIAAIAAAACAAUAAgAJAAEAAAACAAYAAgAJAAIAAAACAP//AgAIAAEAAAACAAAAAgAIAAIAAAADAP//AgAJAAEAAAADAAAAAgAJAAIAAAAAAP//AgAIAAEAAAAAAAAAAgAIAAIAAAABAP//AgAJAAEAAAABAAAAAgAJAAIAAAA="
data = base64.b64decode(data_b64)

print(f"Total length of data: {len(data)}")

# Let's print out all 12-byte blocks. But wait!
# If the header is 8 bytes or 2 bytes, let's see.
# Usually, Godot 4 formats the PackedByteArray in tscn as:
# byte 0-7 or 0-3: header?
# Let's try different headers. If we assume header is 0 bytes or 2 bytes or 4 bytes or 8 bytes.
# If header is 8 bytes, let's print blocks:
for header_size in [0, 2, 4, 8]:
    print(f"\n--- Trying header size: {header_size} ---")
    remaining = data[header_size:]
    num_blocks = len(remaining) // 12
    print(f"Number of blocks: {num_blocks}, remainder: {len(remaining) % 12}")
    for i in range(num_blocks):
        block = remaining[i*12 : (i+1)*12]
        x, y, source_id, atlas_x, atlas_y, alternative = struct.unpack("<hhhhhh", block)
        print(f"Block {i}: x={x}, y={y}, source_id={source_id}, atlas_coords=({atlas_x},{atlas_y}), alternative={alternative}")
