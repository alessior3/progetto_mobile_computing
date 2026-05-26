extends CanvasLayer

func _ready() -> void:
    # Show the route name rect initially
    if has_node("RouteNameRect"):
        var rect = $RouteNameRect
        rect.visible = true
        rect.modulate.a = 1.0
        # Wait before fading
        await get_tree().create_timer(2.0).timeout
        # Fade out over 0.8 seconds
        var tween = get_tree().create_tween()
        tween.tween_property(rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_LINEAR)
        await tween.finished
        rect.visible = false
