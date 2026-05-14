shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // Controlliamo se il pixel è "grigio chiaro" o "bianco" (i tipici colori dei quadratini)
    bool is_white = color.r > 0.9 && color.g > 0.9 && color.b > 0.9;
    bool is_grey = color.r > 0.74 && color.r < 0.76 && color.g > 0.74 && color.g < 0.76 && color.b > 0.74 && color.b < 0.76;
    
    if (is_white || is_grey) {
        discard; // Rendi il pixel trasparente
    }
    
    COLOR = color;
}
