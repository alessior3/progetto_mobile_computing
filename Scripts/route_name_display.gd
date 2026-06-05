extends CanvasLayer

func _ready() -> void:
    if has_node("RouteNameRect"):
        var rect = $RouteNameRect
        
        # Load the custom visual style
        var panel_texture = preload("res://Ninja Adventure - Asset Pack/Ui/Dialog/DialogueBoxSimple.png")
        var custom_font = preload("res://Ninja Adventure - Asset Pack/Ui/Font/NormalFont.ttf")
        
        # Make the background ColorRect transparent
        if rect is ColorRect:
            rect.color = Color(1, 1, 1, 0) 
            
            # Create a NinePatchRect for the frame
            var nine_patch = NinePatchRect.new()
            nine_patch.texture = panel_texture
            # Typical margins for DialogBoxSimple
            nine_patch.patch_margin_left = 12
            nine_patch.patch_margin_top = 12
            nine_patch.patch_margin_right = 12
            nine_patch.patch_margin_bottom = 12
            nine_patch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            rect.add_child(nine_patch)
            nine_patch.name = "BackgroundPanel"
            rect.move_child(nine_patch, 0)
            
        var label = rect.get_node_or_null("RouteNameLabel")
        if label:
            # Apply pixel-art styling similar to the "percorso 30" sprite
            label.add_theme_font_override("font", custom_font)
            label.add_theme_font_size_override("font_size", 24)
            label.add_theme_color_override("font_color", Color(1, 1, 1, 1)) # White text
            label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1)) # Black outline
            label.add_theme_constant_override("outline_size", 4)
            label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
            label.add_theme_constant_override("shadow_offset_x", 1)
            label.add_theme_constant_override("shadow_offset_y", 2)
            
            # Ensure text is properly centered
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            
            if "route_number" in self and label.text == "" or label.text == "Label":
                label.text = "Percorso " + str(get("route_number"))
        
        rect.visible = true
        rect.modulate.a = 1.0
        await get_tree().create_timer(2.0).timeout
        
        var tween = get_tree().create_tween()
        tween.tween_property(rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_LINEAR)
        await tween.finished
        rect.visible = false
