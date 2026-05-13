extends CanvasLayer

class_name TransitionManager

signal transition_done

@export var transition_time = 1.0

@onready var color_rect: ColorRect = $ColorRect

var next_scene_path: String
var is_transitioning = false
var player_spawn_position = null

@onready var loading_icon: Sprite2D = $LoadingIcon

func _ready() -> void:
	color_rect.modulate.a = 0
	color_rect.visible = false 
	loading_icon.visible = false
	

func fade_out():
	is_transitioning = true
	color_rect.modulate.a = 0
	color_rect.visible = true
	
	var current_scene_path = ""
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path != null:
		current_scene_path = get_tree().current_scene.scene_file_path.to_lower()
		
	if next_scene_path.to_lower().contains("percorso2") and current_scene_path.contains("villaggio2"):
		loading_icon.visible = true
		loading_icon.frame = 0
		
		var anim_tween = get_tree().create_tween()
		anim_tween.tween_property(loading_icon, "frame", 8, 4.0).set_trans(Tween.TRANS_LINEAR)

		

	var tween = get_tree().create_tween()
	tween.tween_property(color_rect, "modulate:a", 1, transition_time)
	tween.finished.connect(on_fade_out_completed)
	
func on_fade_out_completed():
	get_tree().change_scene_to_file(next_scene_path)
	fade_in()
	
func fade_in():
	var tween = get_tree().create_tween()
	tween.tween_property(color_rect, "modulate:a", 0, transition_time)
	tween.finished.connect(on_fade_in_finished)
	
func on_fade_in_finished():
	is_transitioning = false
	color_rect.visible = false 
	if loading_icon != null:
		loading_icon.visible = false
	transition_done.emit()
	
func change_scene(target_scene: Variant):
	if is_transitioning:
		return
	if target_scene is String:
		next_scene_path = target_scene
	elif target_scene is PackedScene:
		next_scene_path = target_scene.resource_path
	fade_out()
