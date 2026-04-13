#extends CharacterBody2D
#
#signal feeding_finished
#
#@onready var bowl_sprite = $Bowl
#@onready var food_sprite = $food
#@onready var eat_point = $Marker2D
#
## 在 Inspector 面板中手动拖入空碗和满碗图片
#@export var bowl_empty_texture: Texture2D
#@export var bowl_full_texture: Texture2D
#
#var is_full = false
#var is_feeding = false
#
#var food_origin_pos: Vector2
#var food_origin_scale: Vector2
#
#func _ready():
	#input_pickable = false
	#visible = false
	#food_sprite.visible = false
	#
	#food_origin_pos = food_sprite.position
	#food_origin_scale = food_sprite.scale
	#
	## 初始状态设置为空碗
	#if bowl_empty_texture != null:
		#bowl_sprite.texture = bowl_empty_texture
#
#func show_and_feed():
	#if is_feeding or is_full:
		#return
	#
	#visible = true
	#start_feeding_animation()
#
#func start_feeding_animation():
	#is_feeding = true
	#
	## ========= 初始：在上方出现 =========
	#food_sprite.visible = true
	#food_sprite.position = food_origin_pos + Vector2(0, -55)
	#food_sprite.scale = food_origin_scale * 0.5
	#food_sprite.rotation = deg_to_rad(-55)
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
	## ========= 第二阶段：倾倒 =========
	#tween.tween_property(food_sprite, "position", food_origin_pos + Vector2(0, 12), 1)
	#tween.parallel().tween_property(food_sprite, "scale", food_origin_scale * 1.05, 1)
#
	## ========= 第三阶段：直接消失 =========
	#tween.tween_interval(0.1)
	#tween.tween_property(food_sprite, "modulate:a", 0.0, 0.2)
#
	#await tween.finished
#
	## 倾倒结束后，把碗切换成满碗图片
	#if bowl_full_texture != null:
		#bowl_sprite.texture = bowl_full_texture
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
	#visible = false

extends CharacterBody2D

signal feeding_finished

# ====================【新增：喂水结束信号】====================
signal watering_finished
# ========================================================

@onready var bowl_sprite = $Bowl
@onready var food_sprite = $food

# ====================【新增：water_sprite，对应 food_sprite】====================
@onready var water_sprite = $water
# =======================================================================

@onready var eat_point = $Marker2D

# ====================【修改：补充“满食物盆 / 满水盆”两种状态贴图】====================
# 在 Inspector 面板中手动拖入：
# 1. 空盆图片
# 2. 装满食物的盆图片
# 3. 装满水的盆图片
@export var bowl_empty_texture: Texture2D
@export var bowl_full_food_texture: Texture2D
@export var bowl_full_water_texture: Texture2D
# ==============================================================================

var is_full = false
var is_feeding = false

# ====================【新增：记录当前是否在喂水】====================
var is_watering = false
# ============================================================

# ====================【新增：记录当前盆里装的是食物还是水】====================
var is_food_mode = false
var is_water_mode = false
# =====================================================================

var food_origin_pos: Vector2
var food_origin_scale: Vector2

# ====================【新增：water 的初始位置与缩放】====================
var water_origin_pos: Vector2
var water_origin_scale: Vector2
# ================================================================

func _ready():
	input_pickable = false
	visible = false
	food_sprite.visible = false
	
	# ====================【新增：初始隐藏 water_sprite】====================
	water_sprite.visible = false
	# ================================================================
	
	food_origin_pos = food_sprite.position
	food_origin_scale = food_sprite.scale
	
	# ====================【新增：记录 water_sprite 初始信息】====================
	water_origin_pos = water_sprite.position
	water_origin_scale = water_sprite.scale
	# ===================================================================
	
	# 初始状态设置为空碗
	if bowl_empty_texture != null:
		bowl_sprite.texture = bowl_empty_texture

func show_and_feed():
	if is_feeding or is_full:
		return
	
	visible = true
	start_feeding_animation()

# ====================【新增：喂水入口】====================
func show_and_water():
	if is_feeding or is_full:
		return
	
	visible = true
	start_watering_animation()
# =====================================================

func start_feeding_animation():
	is_feeding = true
	is_watering = false
	
	# ====================【新增：标记当前为食物模式】====================
	is_food_mode = true
	is_water_mode = false
	# ==============================================================
	
	# ====================【新增：喂食时确保 water_sprite 隐藏】====================
	water_sprite.visible = false
	# ===================================================================
	
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

	# ====================【修改：喂食结束后切换到“满食物盆”状态】====================
	if bowl_full_food_texture != null:
		bowl_sprite.texture = bowl_full_food_texture
	# ========================================================================

	# ========= 重置 =========
	food_sprite.visible = false
	food_sprite.position = food_origin_pos
	food_sprite.scale = food_origin_scale
	food_sprite.rotation = 0.0
	food_sprite.modulate.a = 1.0

	is_full = true
	is_feeding = false

	emit_signal("feeding_finished")
	
# ====================【新增：喂水动画，改为使用 water_sprite】====================
func start_watering_animation():
	is_feeding = true
	is_watering = true
	
	# ====================【新增：标记当前为水模式】====================
	is_food_mode = false
	is_water_mode = true
	# ============================================================
	
	# ====================【新增：喂水时确保 food_sprite 隐藏】====================
	food_sprite.visible = false
	# ==================================================================
	
	# ========= 初始：在上方出现 =========
	water_sprite.visible = true
	water_sprite.position = water_origin_pos + Vector2(0, -55)
	water_sprite.scale = water_origin_scale * 0.5
	water_sprite.rotation = deg_to_rad(-55)
	water_sprite.modulate.a = 0.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# ========= 第一阶段：出现 =========
	tween.tween_property(water_sprite, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(water_sprite, "scale", water_origin_scale, 0.15)

	tween.tween_interval(0.1)

	# ========= 第二阶段：倾倒 =========
	tween.tween_property(water_sprite, "position", water_origin_pos + Vector2(0, 12), 1)
	tween.parallel().tween_property(water_sprite, "scale", water_origin_scale * 1.05, 1)

	# ========= 第三阶段：直接消失 =========
	tween.tween_interval(0.1)
	tween.tween_property(water_sprite, "modulate:a", 0.0, 0.2)

	await tween.finished

	# ====================【修改：喂水结束后切换到“满水盆”状态】====================
	if bowl_full_water_texture != null:
		bowl_sprite.texture = bowl_full_water_texture
	# ======================================================================

	# ========= 重置 =========
	water_sprite.visible = false
	water_sprite.position = water_origin_pos
	water_sprite.scale = water_origin_scale
	water_sprite.rotation = 0.0
	water_sprite.modulate.a = 1.0

	is_full = true
	is_feeding = false
	is_watering = false

	emit_signal("watering_finished")
# ========================================================================

func set_empty():
	if bowl_empty_texture != null:
		bowl_sprite.texture = bowl_empty_texture
	
	is_full = false
	visible = false

	# ====================【新增：清空时同时复位 food / water 状态】====================
	is_watering = false
	is_food_mode = false
	is_water_mode = false
	
	food_sprite.visible = false
	food_sprite.position = food_origin_pos
	food_sprite.scale = food_origin_scale
	food_sprite.rotation = 0.0
	food_sprite.modulate.a = 1.0
	
	water_sprite.visible = false
	water_sprite.position = water_origin_pos
	water_sprite.scale = water_origin_scale
	water_sprite.rotation = 0.0
	water_sprite.modulate.a = 1.0
	# =========================================================================
