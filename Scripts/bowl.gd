#extends CharacterBody2D
#
##signal bowl_clicked
#signal feeding_finished
#
#@onready var bowl_sprite = $Bowl
#@onready var food_sprite = $food
#@onready var eat_point = $Marker2D
#
## ====================【新增】====================
## 在 Inspector 面板中手动拖入空碗和满碗图片
#@export var bowl_empty_texture: Texture2D
#@export var bowl_full_texture: Texture2D
## ==============================================
#
#var is_full = false
#var is_feeding = false
#
#var food_origin_pos: Vector2
#var food_origin_scale: Vector2
#
#func _ready():
	#input_pickable = true
	#food_sprite.visible = false
	#
	#food_origin_pos = food_sprite.position
	#food_origin_scale = food_sprite.scale
	#
	## ====================【新增】====================
	## 初始状态设置为空碗
	#if bowl_empty_texture != null:
		#bowl_sprite.texture = bowl_empty_texture
	## ==============================================
#
#func _input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton \
	#and event.pressed \
	#and event.button_index == MOUSE_BUTTON_LEFT:
		#if is_feeding or is_full:
			#return
		#
		#emit_signal("bowl_clicked")
		#start_feeding_animation()
#
#func start_feeding_animation():
	#is_feeding = true
	#
	## ========= 初始：在上方出现 =========
	#food_sprite.visible = true
	#food_sprite.position = food_origin_pos + Vector2(0, -55)
	#food_sprite.scale = food_origin_scale * 0.5
	#food_sprite.rotation = deg_to_rad(-55)   # 一开始就倾斜
	#food_sprite.modulate.a = 0.0
#
	#var tween = create_tween()
	#tween.set_trans(Tween.TRANS_SINE)
	#tween.set_ease(Tween.EASE_OUT)
#
	## ========= 第一阶段：出现 =========
	#tween.tween_property(food_sprite, "modulate:a", 1.0, 0.15)
	#tween.parallel().tween_property(food_sprite, "scale", food_origin_scale, 0.15)
#
	#tween.tween_interval(0.1)
#
	## ========= 第二阶段：倾倒（保持倾斜，不回正）=========
	#tween.tween_property(food_sprite, "position", food_origin_pos + Vector2(0, 12), 1)
	#tween.parallel().tween_property(food_sprite, "scale", food_origin_scale * 1.05, 1)
#
	## ⭐ 注意：这里不再 rotation -> 0，保持倾倒状态
#
	## ========= 第三阶段：直接消失 =========
	#tween.tween_interval(0.1)
	#tween.tween_property(food_sprite, "modulate:a", 0.0, 0.2)
#
	#await tween.finished
#
	## ====================【新增】====================
	## 倾倒结束后，把碗切换成满碗图片
	#if bowl_full_texture != null:
		#bowl_sprite.texture = bowl_full_texture
	## ==============================================
#
	## ========= 重置 =========
	#food_sprite.visible = false
	#food_sprite.position = food_origin_pos
	#food_sprite.scale = food_origin_scale
	#food_sprite.rotation = 0.0
	#food_sprite.modulate.a = 1.0
#
	#is_full = true
	#is_feeding = false
#
	#emit_signal("feeding_finished")
	#
#func set_empty():
	#if bowl_empty_texture != null:
		#bowl_sprite.texture = bowl_empty_texture
	#
	#is_full = false

extends CharacterBody2D

signal feeding_finished

@onready var bowl_sprite = $Bowl
@onready var food_sprite = $food
@onready var eat_point = $Marker2D

# ====================【新增】====================
# 在 Inspector 面板中手动拖入空碗和满碗图片
@export var bowl_empty_texture: Texture2D
@export var bowl_full_texture: Texture2D
# ==============================================

var is_full = false
var is_feeding = false

var food_origin_pos: Vector2
var food_origin_scale: Vector2

func _ready():
	input_pickable = false
	visible = false
	food_sprite.visible = false
	
	food_origin_pos = food_sprite.position
	food_origin_scale = food_sprite.scale
	
	# 初始状态设置为空碗
	if bowl_empty_texture != null:
		bowl_sprite.texture = bowl_empty_texture

func show_and_feed():
	if is_feeding or is_full:
		return
	
	visible = true
	start_feeding_animation()

func start_feeding_animation():
	is_feeding = true
	
	# ========= 初始：在上方出现 =========
	food_sprite.visible = true
	food_sprite.position = food_origin_pos + Vector2(0, -55)
	food_sprite.scale = food_origin_scale * 0.5
	food_sprite.rotation = deg_to_rad(-55)
	food_sprite.modulate.a = 0.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# ========= 第一阶段：出现 =========
	tween.tween_property(food_sprite, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(food_sprite, "scale", food_origin_scale, 0.15)

	tween.tween_interval(0.1)

	# ========= 第二阶段：倾倒 =========
	tween.tween_property(food_sprite, "position", food_origin_pos + Vector2(0, 12), 1)
	tween.parallel().tween_property(food_sprite, "scale", food_origin_scale * 1.05, 1)

	# ========= 第三阶段：直接消失 =========
	tween.tween_interval(0.1)
	tween.tween_property(food_sprite, "modulate:a", 0.0, 0.2)

	await tween.finished

	# 倾倒结束后，把碗切换成满碗图片
	if bowl_full_texture != null:
		bowl_sprite.texture = bowl_full_texture

	# ========= 重置 =========
	food_sprite.visible = false
	food_sprite.position = food_origin_pos
	food_sprite.scale = food_origin_scale
	food_sprite.rotation = 0.0
	food_sprite.modulate.a = 1.0

	is_full = true
	is_feeding = false

	emit_signal("feeding_finished")
	
func set_empty():
	if bowl_empty_texture != null:
		bowl_sprite.texture = bowl_empty_texture
	
	is_full = false
	visible = false
