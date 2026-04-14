extends Area2D

@export_file("*.tscn") var target_scene_path: String
@onready var highlight: Polygon2D = $Polygon2D

func _ready() -> void:
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if highlight != null:
		highlight.visible = true
		highlight.color = Color(1, 1, 0, 0.0) # 初始完全透明
		highlight.z_index = 100

func _input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		if target_scene_path != "":
			PawTransition.transition_to_scene(target_scene_path)
			#get_tree().change_scene_to_file(target_scene_path)

func _on_mouse_entered() -> void:
	if highlight != null:
		highlight.color = Color(1.0, 0.7, 0.85, 0.22)

func _on_mouse_exited() -> void:
	if highlight != null:
		highlight.color = Color(1, 1, 0, 0.0) # 恢复透明
