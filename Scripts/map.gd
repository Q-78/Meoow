#电脑调试版
#extends Node2D
#
#@onready var camera: Camera2D = $Camera2D
#
#@export var edge_margin: float = 80.0
#@export var camera_speed: float = 500.0
#@export var smooth_speed: float = 10.0
#
## 手动设置“有效地图边界”
#@export var map_left: float = -220.0
#@export var map_right: float = 980.0
#@export var map_top: float = 150.0
#@export var map_bottom: float = 1300.0
#
#var target_camera_pos: Vector2
#
#func _ready() -> void:
	#target_camera_pos = Vector2(
		#(map_left + map_right) / 2.0,
		#(map_top + map_bottom) / 2.0
	#)
	#camera.global_position = target_camera_pos
#
#func _process(delta: float) -> void:
	#update_camera_target(delta)
	#camera.global_position = camera.global_position.lerp(target_camera_pos, delta * smooth_speed)
#
#func update_camera_target(delta: float) -> void:
	#var viewport_size = get_viewport_rect().size
	#var mouse_pos = get_viewport().get_mouse_position()
#
	#var move_dir = Vector2.ZERO
#
	#if mouse_pos.x <= edge_margin:
		#move_dir.x = -1
	#elif mouse_pos.x >= viewport_size.x - edge_margin:
		#move_dir.x = 1
#
	#if mouse_pos.y <= edge_margin:
		#move_dir.y = -1
	#elif mouse_pos.y >= viewport_size.y - edge_margin:
		#move_dir.y = 1
#
	#if move_dir != Vector2.ZERO:
		#move_dir = move_dir.normalized()
#
	#target_camera_pos += move_dir * camera_speed * delta
	#target_camera_pos = clamp_camera_to_bounds(target_camera_pos, viewport_size)
#
#func clamp_camera_to_bounds(pos: Vector2, viewport_size: Vector2) -> Vector2:
	#var half_view = viewport_size / 2.0
#
	#var min_x = map_left + half_view.x
	#var max_x = map_right - half_view.x
	#var min_y = map_top + half_view.y
	#var max_y = map_bottom - half_view.y
#
	#if min_x > max_x:
		#pos.x = (map_left + map_right) / 2.0
	#else:
		#pos.x = clamp(pos.x, min_x, max_x)
#
	#if min_y > max_y:
		#pos.y = (map_top + map_bottom) / 2.0
	#else:
		#pos.y = clamp(pos.y, min_y, max_y)
#
	#return pos


#extends Node2D
#
#@onready var camera: Camera2D = $Camera2D
#
#@export var smooth_speed: float = 10.0
#@export var drag_sensitivity: float = 1.0
#
## 手动设置“有效地图边界”
#@export var map_left: float = -220.0
#@export var map_right: float = 980.0
#@export var map_top: float = 150.0
#@export var map_bottom: float = 1300.0
#
#var target_camera_pos: Vector2
#var is_dragging: bool = false
#
#func _ready() -> void:
	#target_camera_pos = Vector2(
		#(map_left + map_right) / 2.0,
		#(map_top + map_bottom) / 2.0
	#)
	#camera.global_position = target_camera_pos
#
#func _process(delta: float) -> void:
	#camera.global_position = camera.global_position.lerp(target_camera_pos, delta * smooth_speed)
#
#func _input(event: InputEvent) -> void:
	#var viewport_size = get_viewport_rect().size
#
	#if event is InputEventScreenTouch:
		#is_dragging = event.pressed
#
	#elif event is InputEventScreenDrag and is_dragging:
		#target_camera_pos -= event.relative * drag_sensitivity
		#target_camera_pos = clamp_camera_to_bounds(target_camera_pos, viewport_size)
#
#func clamp_camera_to_bounds(pos: Vector2, viewport_size: Vector2) -> Vector2:
	#var half_view = viewport_size / 2.0
#
	#var min_x = map_left + half_view.x
	#var max_x = map_right - half_view.x
	#var min_y = map_top + half_view.y
	#var max_y = map_bottom - half_view.y
#
	#if min_x > max_x:
		#pos.x = (map_left + map_right) / 2.0
	#else:
		#pos.x = clamp(pos.x, min_x, max_x)
#
	#if min_y > max_y:
		#pos.y = (map_top + map_bottom) / 2.0
	#else:
		#pos.y = clamp(pos.y, min_y, max_y)
#
	#return pos


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
	target_camera_pos = Vector2(
		(map_left + map_right) / 2.0,
		(map_top + map_bottom) / 2.0
	)
	camera.global_position = target_camera_pos

func _process(delta: float) -> void:
	if is_dragging:
		camera.global_position = target_camera_pos
	else:
		camera.global_position = camera.global_position.lerp(target_camera_pos, delta * smooth_speed)

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
