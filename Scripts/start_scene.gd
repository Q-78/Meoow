#extends Node2D
#
#@export_file("*.tscn") var next_scene_path: String = "res://Scenes/playground.tscn"
#
#@export var cat_wait_before_roll: float = 0.3
#@export var logo_show_delay: float = 0.2
#@export var hold_time: float = 4.0
#@export var allow_skip: bool = true
#@export var cat_fade_duration: float = 0.4
#
#@onready var cat = $cat001
#@onready var logo = $Logo
#
#var can_skip: bool = false
#var is_changing_scene: bool = false
#
#func _ready() -> void:
	#if logo:
		#logo.modulate.a = 0.0
	#
	#if cat:
		#cat.modulate.a = 1.0
	#
	#start_splash()
#
#
#func start_splash() -> void:
	#await get_tree().create_timer(cat_wait_before_roll).timeout
	#
	## 1. 播放小猫 roll
	#if cat and cat.has_method("play_splash_roll"):
		#await cat.play_splash_roll()
	#
	## 2. 小猫淡出消失
	#await fade_out_cat()
	#
	## 3. 稍微停顿一下，再显示 logo
	#await get_tree().create_timer(logo_show_delay).timeout
	#
	## 4. 播放 logo 动画，并等动画播完
	#await play_logo_animation()
	#
	## 5. logo 出现后允许点击跳过
	#can_skip = allow_skip
	#
	## 6. 开机界面多停留一会儿
	#await get_tree().create_timer(hold_time).timeout
	#
	#change_to_next_scene()
#
#
#func fade_out_cat() -> void:
	#if not cat:
		#return
	#
	#var tween = create_tween()
	#tween.tween_property(cat, "modulate:a", 0.0, cat_fade_duration)
	#await tween.finished
	#
	#cat.visible = false
#
#
#func play_logo_animation() -> void:
	#if not logo:
		#return
	#
	#var start_pos = logo.position
	#logo.position = start_pos + Vector2(0, 20)
	#logo.modulate.a = 0.0
	#
	#var tween = create_tween()
	#tween.set_parallel(true)
	#tween.tween_property(logo, "modulate:a", 1.0, 0.6)
	#tween.tween_property(logo, "position", start_pos, 0.6)
	#await tween.finished
#
#
#func _unhandled_input(event: InputEvent) -> void:
	#if not allow_skip:
		#return
	#
	#if not can_skip:
		#return
	#
	#if is_changing_scene:
		#return
	#
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#change_to_next_scene()
	#elif event is InputEventScreenTouch and event.pressed:
		#change_to_next_scene()
	#elif event is InputEventKey and event.pressed:
		#change_to_next_scene()
#
#
#func change_to_next_scene() -> void:
	#if is_changing_scene:
		#return
	#
	#is_changing_scene = true
	#can_skip = false
	#
	#if next_scene_path != "":
		#get_tree().change_scene_to_file(next_scene_path)

extends Node2D

@export_file("*.tscn") var next_scene_path: String = "res://Scenes/playground.tscn"

@export var cat_wait_before_roll: float = 0.3
@export var logo_show_delay: float = 0.2
@export var hold_time: float = 4.0
@export var allow_skip: bool = true

@onready var cat = $cat001
@onready var logo = $Logo

var can_skip: bool = false
var is_changing_scene: bool = false

func _ready() -> void:
	if logo:
		logo.modulate.a = 0.0
	
	if cat:
		cat.modulate.a = 1.0
		cat.visible = true
	
	start_splash()


func start_splash() -> void:
	await get_tree().create_timer(cat_wait_before_roll).timeout
	
	# 1. 播放小猫 roll
	if cat and cat.has_method("play_splash_roll"):
		await cat.play_splash_roll()
	
	# 2. 小猫不消失，稍微停顿一下再显示 logo
	await get_tree().create_timer(logo_show_delay).timeout
	
	# 3. 播放 logo 动画，并等动画播完
	await play_logo_animation()
	
	# 4. logo 出现后允许点击跳过
	can_skip = allow_skip
	
	# 5. 开机界面多停留一会儿
	await get_tree().create_timer(hold_time).timeout
	
	change_to_next_scene()


func play_logo_animation() -> void:
	if not logo:
		return
	
	var start_pos = logo.position
	logo.position = start_pos + Vector2(0, 20)
	logo.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(logo, "modulate:a", 1.0, 0.6)
	tween.tween_property(logo, "position", start_pos, 0.6)
	await tween.finished


func _unhandled_input(event: InputEvent) -> void:
	if not allow_skip:
		return
	
	if not can_skip:
		return
	
	if is_changing_scene:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		change_to_next_scene()
	elif event is InputEventScreenTouch and event.pressed:
		change_to_next_scene()
	elif event is InputEventKey and event.pressed:
		change_to_next_scene()


func change_to_next_scene() -> void:
	if is_changing_scene:
		return
	
	is_changing_scene = true
	can_skip = false
	
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
