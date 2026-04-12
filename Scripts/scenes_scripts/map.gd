extends Node2D

@onready var camera: Camera2D = $Camera2D

@export var smooth_speed: float = 12.0
@export var drag_sensitivity: float = 1.0

# 手动设置“有效地图边界”
@export var map_left: float = -220.0
@export var map_right: float = 980.0
@export var map_top: float = 150.0
@export var map_bottom: float = 1300.0

var target_camera_pos: Vector2
var is_dragging: bool = false

func _ready() -> void:
	# 进入 map 时，记录当前场景
	SceneMemory.set_last_scene(scene_file_path)

	target_camera_pos = Vector2(
		(map_left + map_right) / 2.0,
		(map_top + map_bottom) / 2.0
	)

	target_camera_pos = clamp_camera_to_bounds(
		target_camera_pos,
		get_viewport_rect().size
	)

	camera.global_position = target_camera_pos

func _process(delta: float) -> void:
	if is_dragging:
		camera.global_position = target_camera_pos
	else:
		camera.global_position = camera.global_position.lerp(target_camera_pos, delta * smooth_speed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_EXIT_TREE:
		SceneMemory.set_last_scene(scene_file_path)

func _input(event: InputEvent) -> void:
	var viewport_size = get_viewport_rect().size

	if event is InputEventScreenTouch:
		is_dragging = event.pressed

	elif event is InputEventScreenDrag and is_dragging:
		target_camera_pos -= event.relative * drag_sensitivity
		target_camera_pos = clamp_camera_to_bounds(target_camera_pos, viewport_size)

func clamp_camera_to_bounds(pos: Vector2, viewport_size: Vector2) -> Vector2:
	var half_view = viewport_size / 2.0

	var min_x = map_left + half_view.x
	var max_x = map_right - half_view.x
	var min_y = map_top + half_view.y
	var max_y = map_bottom - half_view.y

	if min_x > max_x:
		pos.x = (map_left + map_right) / 2.0
	else:
		pos.x = clamp(pos.x, min_x, max_x)

	if min_y > max_y:
		pos.y = (map_top + map_bottom) / 2.0
	else:
		pos.y = clamp(pos.y, min_y, max_y)

	return pos

# 如果你有“返回主场景”按钮，可以加这个函数
func _on_back_pressed() -> void:
	var next_scene := "res://Scenes/playground.tscn"
	SceneMemory.set_last_scene(next_scene)
	PawTransition.transition_to_scene("res://Scenes/map.tscn")
	#get_tree().change_scene_to_file(next_scene)
