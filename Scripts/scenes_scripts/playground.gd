#extends Node2D
#
#@export var intimacy_label: Label
#
#@onready var cat_node = $cat001
#@onready var bowl_node = $bowl
#@onready var feed_button = $FeedButton
#
#var is_feeding_flow_running: bool = false
#
#func _ready() -> void:
	## 进入 playground 时，记录当前场景
	#SceneMemory.set_last_scene(scene_file_path)
#
	#bowl_node.feeding_finished.connect(_on_bowl_feeding_finished)
	#cat_node.eat_finished.connect(_on_cat_eat_finished)
	#feed_button.pressed.connect(_on_feed_button_pressed)
#
#func _process(delta: float) -> void:
	#pass
#
## ====================【新增：点击场景让猫移动】====================
#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton \
	#and event.button_index == MOUSE_BUTTON_LEFT \
	#and event.pressed:
		#cat_node.go_to_point(get_global_mouse_position())
## ================================================================
#
#func _notification(what: int) -> void:
	#if what == NOTIFICATION_APPLICATION_PAUSED:
		#SceneMemory.set_last_scene(scene_file_path)
	#elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		#SceneMemory.set_last_scene(scene_file_path)
	#elif what == NOTIFICATION_EXIT_TREE:
		#SceneMemory.set_last_scene(scene_file_path)
#
#func _on_feed_button_pressed() -> void:
	#if is_feeding_flow_running:
		#return
	#is_feeding_flow_running = true
	#print("点击了喂食按钮")
	#bowl_node.show_and_feed()
#
#func _on_bowl_feeding_finished() -> void:
	#var target_pos = $bowl/Marker2D.global_position
	#print("主场景传给猫的目标点:", target_pos)
	#cat_node.go_to_eat(target_pos)
#
#func _on_cat_eat_finished() -> void:
	#bowl_node.set_empty()
	#is_feeding_flow_running = false
#
#func _on_to_map_pressed() -> void:
	#var next_scene := "res://Scenes/map.tscn"
	#SceneMemory.set_last_scene(next_scene)
	#PawTransition.transition_to_scene(next_scene)
	##get_tree().change_scene_to_file(next_scene)


extends Node2D

@export var intimacy_label: Label

@onready var cat_node = $cat001
@onready var bowl_node = $bowl
@onready var feed_button = $FeedButton

# ====================【修改：这里不再找 $water，只保留喂水按钮】====================
@onready var water_button = $WaterButton
# ===========================================================================

var is_feeding_flow_running: bool = false

# ====================【新增：喂水流程锁】====================
var is_watering_flow_running: bool = false
# ========================================================

func _ready() -> void:
	# 进入 playground 时，记录当前场景
	SceneMemory.set_last_scene(scene_file_path)

	bowl_node.feeding_finished.connect(_on_bowl_feeding_finished)
	cat_node.eat_finished.connect(_on_cat_eat_finished)
	feed_button.pressed.connect(_on_feed_button_pressed)

	# ====================【修改：喂水信号也连到 bowl_node】====================
	bowl_node.watering_finished.connect(_on_water_watering_finished)
	cat_node.drink_finished.connect(_on_cat_drink_finished)
	water_button.pressed.connect(_on_water_button_pressed)
	# =====================================================================

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		cat_node.go_to_point(get_global_mouse_position())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_EXIT_TREE:
		SceneMemory.set_last_scene(scene_file_path)

func _on_feed_button_pressed() -> void:
	if is_feeding_flow_running or is_watering_flow_running:
		return
	is_feeding_flow_running = true
	print("点击了喂食按钮")
	bowl_node.show_and_feed()

func _on_water_button_pressed() -> void:
	if is_feeding_flow_running or is_watering_flow_running:
		return
	is_watering_flow_running = true
	print("点击了喂水按钮")
	# ====================【修改：喂水也调用同一个 bowl_node】====================
	bowl_node.show_and_water()
	# =====================================================================

func _on_bowl_feeding_finished() -> void:
	var target_pos = $bowl/Marker2D.global_position
	print("主场景传给猫的目标点:", target_pos)
	cat_node.go_to_eat(target_pos)

func _on_water_watering_finished() -> void:
	var target_pos = $bowl/Marker2D.global_position
	print("主场景传给猫的喝水目标点:", target_pos)
	cat_node.go_to_drink(target_pos)

func _on_cat_eat_finished() -> void:
	bowl_node.set_empty()
	is_feeding_flow_running = false

func _on_cat_drink_finished() -> void:
	bowl_node.set_empty()
	is_watering_flow_running = false

func _on_to_map_pressed() -> void:
	var next_scene := "res://Scenes/map.tscn"
	SceneMemory.set_last_scene(next_scene)
	PawTransition.transition_to_scene(next_scene)
