#extends CharacterBody2D
#
#signal eat_finished
#
#@export var splash_mode: bool = false
#
#@export var move_speed : float = 200
#@export var eat_speed : float = 250
#@export var animator : AnimatedSprite2D
#
#@export var hand_scene : PackedScene
#@export var heart_scene : PackedScene
#
#@onready var cat_collision = $CollisionShape2D
#
## ====================【新增：普通移动边界】====================
#@export var walk_min_x: float = -400.0
#@export var walk_max_x: float = 5000.0
#@export var walk_min_y: float = 0.0
#@export var walk_max_y: float = 3000.0
#
## 当前普通移动方向（只用于普通 WALK，不影响吃饭）
#var walk_direction: Vector2 = Vector2.ZERO
## ===========================================================
#
## ====================【新增：点击地面移动】====================
#@export var click_move_arrive_distance: float = 12.0
#
#var is_moving_to_point: bool = false
#var move_target_position: Vector2 = Vector2.ZERO
## ===========================================================
#
## ====================【新增：吃饭控制】====================
#@export var eat_duration : float = 3.0
#@export var food_arrive_distance : float = 20.0
#
#var is_going_to_eat : bool = false
#var is_eating_food : bool = false
#var food_target_position : Vector2 = Vector2.ZERO
## ========================================================
#
#enum State {
	#IDLE,
	#WALK,
	#SLEEP
#}
#
#var current_state : State = State.IDLE
#var state_timer : float = 0.0
#
#func _ready() -> void:
	#if splash_mode:
		#velocity = Vector2.ZERO
		#if animator:
			#animator.play("sit")
	#else:
		#change_state(State.IDLE)
#
#
#func _physics_process(delta: float) -> void:
	#if splash_mode:
		#velocity = Vector2.ZERO
		#return
#
	## ====================【保留原吃饭逻辑，不改】====================
	#if is_going_to_eat:
		#var dir = food_target_position - global_position
		#
		#if dir.length() <= food_arrive_distance:
			#print("到达")
			#global_position = food_target_position
			#velocity = Vector2.ZERO
			#is_going_to_eat = false
			#
			#if not is_eating_food:
				#start_eating_food()
			#return
		#else:
			#velocity = dir.normalized() * eat_speed
			#if animator.animation != "walk":
				#animator.play("walk")
			#animator.flip_h = velocity.x < 0
			#move_and_slide()
			#_clamp_walk_position()
			#return
	#
	#if is_eating_food:
		#velocity = Vector2.ZERO
		#return
	## ==============================================================
#
	## ====================【新增：点击位置移动逻辑】====================
	#if is_moving_to_point:
		#var dir_to_point = move_target_position - global_position
		#
		#if dir_to_point.length() <= click_move_arrive_distance:
			#global_position = move_target_position
			#velocity = Vector2.ZERO
			#is_moving_to_point = false
			#change_state(State.IDLE)
			#return
		#else:
			#velocity = dir_to_point.normalized() * move_speed
			#if animator.animation != "walk":
				#animator.play("walk")
			#animator.flip_h = velocity.x < 0
			#move_and_slide()
			#_clamp_walk_position()
			#return
	## ===============================================================
#
	#state_timer -= delta
#
	#match current_state:
		#State.IDLE:
			#velocity = Vector2.ZERO
		#
		#State.WALK:
			## 普通散步时，先检查是否快碰边界
			#_update_walk_direction_by_boundary()
			#velocity = walk_direction * move_speed
			#animator.flip_h = velocity.x < 0
			#move_and_slide()
			#_clamp_walk_position()
		#
		#State.SLEEP:
			#velocity = Vector2.ZERO
#
	## 时间到了就切换状态
	#if state_timer <= 0:
		#decide_next_state()
#
#
## ======================
## 状态切换逻辑
## ======================
#func change_state(new_state : State):
	#current_state = new_state
	#
	#match new_state:
		#State.IDLE:
			#animator.play("sit")
			## 增加静止时间，让 WALK 占比下降
			#state_timer = randf_range(3.0, 6.0)
		#
		#State.WALK:
			#animator.play("walk")
			#_pick_random_walk_direction()
			#animator.flip_h = walk_direction.x < 0
			## 缩短单次 WALK 时间，让运动占比下降
			#state_timer = randf_range(0.8, 1.8)
		#
		#State.SLEEP:
			#animator.play("sleep")
			## 稍微增加睡眠时间，让整体更偏静态
			#state_timer = randf_range(5.0, 9.0)
#
#
#func decide_next_state():
	#match current_state:
		#State.IDLE:
			## 降低从 IDLE 进入 WALK 的概率
			#if randf() < 0.35:
				#change_state(State.WALK)
			#else:
				#change_state(State.SLEEP)
		#
		#State.WALK:
			## WALK 结束后更大概率回到 IDLE
			#if randf() < 0.8:
				#change_state(State.IDLE)
			#else:
				#change_state(State.SLEEP)
		#
		#State.SLEEP:
			## 睡醒后多数先 idle，少数直接 walk，增加节奏随机性
			#if randf() < 0.75:
				#change_state(State.IDLE)
			#else:
				#change_state(State.WALK)
#
#
## ======================
## 点击逻辑（优先打断状态）
## ======================
#func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("玩家角色被点击！")
		#
		## ⭐ 新增：生成特效
		#spawn_hand(get_global_mouse_position())
		#spawn_heart()
		##spawn_hand(event.position)
		#
		##GameManager.intimacy += 1
		#$AudioStreamPlayer.play()
		##rint(GameManager.intimacy)
		## 打断当前行为
		#current_state = State.IDLE
		## ====================【新增：点到猫本体时取消“去点击点移动”】====================
		#is_moving_to_point = false
		#velocity = Vector2.ZERO
		## ========================================================================
		#
		#animator.play("picked")
		#await get_tree().create_timer(1).timeout
		#animator.play("sit")
		#
#func spawn_hand(pos: Vector2):
	#var hand = hand_scene.instantiate()
	#get_tree().current_scene.add_child(hand)
	#hand.global_position = pos
#
#func spawn_heart():
	#var heart = heart_scene.instantiate()
	#get_tree().current_scene.add_child(heart)
	#heart.global_position = $HeartPos.global_position
#
## ====================【新增：点击某个位置后让猫走过去】====================
#func go_to_point(target_pos: Vector2):
	## 不打断原来的吃饭流程
	#if is_eating_food or is_going_to_eat:
		#return
	#
	#is_moving_to_point = true
	#move_target_position = target_pos
	#
	## 目标点限制在活动边界内
	#move_target_position.x = clamp(move_target_position.x, walk_min_x, walk_max_x)
	#move_target_position.y = clamp(move_target_position.y, walk_min_y, walk_max_y)
## ======================================================================
#
## ====================【保留原吃饭逻辑，不改】====================
#func go_to_eat(target_pos: Vector2):
	#print("收到目标点:", target_pos)
	## ====================【新增：吃饭时取消普通点击移动】====================
	#is_moving_to_point = false
	## =================================================================
	#
	#is_going_to_eat = true
	#is_eating_food = false
	#food_target_position = target_pos
	#
	#if cat_collision:
		#cat_collision.disabled = true
#
#
#func start_eating_food():
	#is_eating_food = true
	#animator.play("eat")
	#$eat.play()
	#
	#await get_tree().create_timer(eat_duration).timeout
	#
	#$eat.stop()
	#is_eating_food = false
	#
	#if cat_collision:
		#cat_collision.disabled = false
	#
	#emit_signal("eat_finished")
	#change_state(State.IDLE)
## ===================================================================
#
#func play_splash_roll() -> void:
	#if not animator:
		#return
	#
	#velocity = Vector2.ZERO
	#if animator.sprite_frames.has_animation("roll"):
		#animator.play("roll")
		#await animator.animation_finished
	#else:
		## 如果暂时没有 roll 动画，就退化成 picked 或 sit
		#if animator.sprite_frames.has_animation("picked"):
			#animator.play("picked")
			#await get_tree().create_timer(1.0).timeout
	#
	#animator.play("sit")
#
#
## ======================
## 新增：普通散步辅助函数
## ======================
#func _pick_random_walk_direction():
	## 以水平移动为主，但加入一点点上下随机
	#var random_x = randf_range(-1.0, 1.0)
	#var random_y = randf_range(-0.35, 0.35)
	#var dir = Vector2(random_x, random_y)
	#
	#if dir.length() < 0.1:
		#dir = Vector2(1, 0)
	#
	#walk_direction = dir.normalized()
	#
	## 如果一开始方向就朝着边界外，立即修正
	#_update_walk_direction_by_boundary()
#
#
#func _update_walk_direction_by_boundary():
	## 靠近左右边界时，强制把 x 方向往回拉
	#if global_position.x <= walk_min_x + 10.0 and walk_direction.x < 0:
		#walk_direction.x = abs(walk_direction.x)
	#elif global_position.x >= walk_max_x - 10.0 and walk_direction.x > 0:
		#walk_direction.x = -abs(walk_direction.x)
	#
	## 靠近上下边界时，强制把 y 方向往回拉
	#if global_position.y <= walk_min_y + 10.0 and walk_direction.y < 0:
		#walk_direction.y = abs(walk_direction.y)
	#elif global_position.y >= walk_max_y - 10.0 and walk_direction.y > 0:
		#walk_direction.y = -abs(walk_direction.y)
	#
	#if walk_direction.length() < 0.1:
		#walk_direction = Vector2(1, 0)
	#else:
		#walk_direction = walk_direction.normalized()
#
#
#func _clamp_walk_position():
	#global_position.x = clamp(global_position.x, walk_min_x, walk_max_x)
	#global_position.y = clamp(global_position.y, walk_min_y, walk_max_y)

extends CharacterBody2D

signal eat_finished

# ====================【新增：喝水结束信号】====================
signal drink_finished
# ========================================================

@export var splash_mode: bool = false

@export var move_speed : float = 200
@export var eat_speed : float = 250
@export var animator : AnimatedSprite2D

@export var hand_scene : PackedScene
@export var heart_scene : PackedScene

@onready var cat_collision = $CollisionShape2D

# ====================【新增：普通移动边界】====================
@export var walk_min_x: float = -400.0
@export var walk_max_x: float = 5000.0
@export var walk_min_y: float = 0.0
@export var walk_max_y: float = 3000.0

# 当前普通移动方向（只用于普通 WALK，不影响吃饭）
var walk_direction: Vector2 = Vector2.ZERO
# ===========================================================

# ====================【新增：点击地面移动】====================
@export var click_move_arrive_distance: float = 12.0

var is_moving_to_point: bool = false
var move_target_position: Vector2 = Vector2.ZERO
# ===========================================================

# ====================【新增：吃饭控制】====================
@export var eat_duration : float = 3.0
@export var food_arrive_distance : float = 20.0

var is_going_to_eat : bool = false
var is_eating_food : bool = false
var food_target_position : Vector2 = Vector2.ZERO
# ========================================================

# ====================【新增：喝水控制】====================
@export var drink_duration : float = 3.0
@export var water_arrive_distance : float = 20.0

var is_going_to_drink : bool = false
var is_drinking_water : bool = false
var water_target_position : Vector2 = Vector2.ZERO
# ========================================================

enum State {
	IDLE,
	WALK,
	SLEEP
}

var current_state : State = State.IDLE
var state_timer : float = 0.0

func _ready() -> void:
	if splash_mode:
		velocity = Vector2.ZERO
		if animator:
			animator.play("sit")
	else:
		change_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if splash_mode:
		velocity = Vector2.ZERO
		return

	# ====================【保留原吃饭逻辑，不改】====================
	if is_going_to_eat:
		var dir = food_target_position - global_position
		
		if dir.length() <= food_arrive_distance:
			print("到达")
			global_position = food_target_position
			velocity = Vector2.ZERO
			is_going_to_eat = false
			
			if not is_eating_food:
				start_eating_food()
			return
		else:
			velocity = dir.normalized() * eat_speed
			if animator.animation != "walk":
				animator.play("walk")
			animator.flip_h = velocity.x < 0
			move_and_slide()
			_clamp_walk_position()
			return
	
	if is_eating_food:
		velocity = Vector2.ZERO
		return
	# ==============================================================

	# ====================【新增：喝水逻辑】====================
	if is_going_to_drink:
		var dir = water_target_position - global_position
		
		if dir.length() <= water_arrive_distance:
			print("到达喝水点")
			global_position = water_target_position
			velocity = Vector2.ZERO
			is_going_to_drink = false
			
			if not is_drinking_water:
				start_drinking_water()
			return
		else:
			velocity = dir.normalized() * eat_speed
			if animator.animation != "walk":
				animator.play("walk")
			animator.flip_h = velocity.x < 0
			move_and_slide()
			_clamp_walk_position()
			return
	
	if is_drinking_water:
		velocity = Vector2.ZERO
		return
	# ========================================================

	# ====================【新增：点击位置移动逻辑】====================
	if is_moving_to_point:
		var dir_to_point = move_target_position - global_position
		
		if dir_to_point.length() <= click_move_arrive_distance:
			global_position = move_target_position
			velocity = Vector2.ZERO
			is_moving_to_point = false
			change_state(State.IDLE)
			return
		else:
			velocity = dir_to_point.normalized() * move_speed
			if animator.animation != "walk":
				animator.play("walk")
			animator.flip_h = velocity.x < 0
			move_and_slide()
			_clamp_walk_position()
			return
	# ===============================================================

	state_timer -= delta

	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		
		State.WALK:
			# 普通散步时，先检查是否快碰边界
			_update_walk_direction_by_boundary()
			velocity = walk_direction * move_speed
			animator.flip_h = velocity.x < 0
			move_and_slide()
			_clamp_walk_position()
		
		State.SLEEP:
			velocity = Vector2.ZERO

	# 时间到了就切换状态
	if state_timer <= 0:
		decide_next_state()


# ======================
# 状态切换逻辑
# ======================
func change_state(new_state : State):
	current_state = new_state
	
	match new_state:
		State.IDLE:
			animator.play("sit")
			# 增加静止时间，让 WALK 占比下降
			state_timer = randf_range(3.0, 6.0)
		
		State.WALK:
			animator.play("walk")
			_pick_random_walk_direction()
			animator.flip_h = walk_direction.x < 0
			# 缩短单次 WALK 时间，让运动占比下降
			state_timer = randf_range(0.8, 1.8)
		
		State.SLEEP:
			animator.play("sleep")
			# 稍微增加睡眠时间，让整体更偏静态
			state_timer = randf_range(5.0, 9.0)


func decide_next_state():
	match current_state:
		State.IDLE:
			# 降低从 IDLE 进入 WALK 的概率
			if randf() < 0.35:
				change_state(State.WALK)
			else:
				change_state(State.SLEEP)
		
		State.WALK:
			# WALK 结束后更大概率回到 IDLE
			if randf() < 0.8:
				change_state(State.IDLE)
			else:
				change_state(State.SLEEP)
		
		State.SLEEP:
			# 睡醒后多数先 idle，少数直接 walk，增加节奏随机性
			if randf() < 0.75:
				change_state(State.IDLE)
			else:
				change_state(State.WALK)


# ======================
# 点击逻辑（优先打断状态）
# ======================
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("玩家角色被点击！")
		
		# ⭐ 新增：生成特效
		spawn_hand(get_global_mouse_position())
		spawn_heart()
		#spawn_hand(event.position)
		
		#GameManager.intimacy += 1
		$AudioStreamPlayer.play()
		#rint(GameManager.intimacy)
		# 打断当前行为
		current_state = State.IDLE
		# ====================【新增：点到猫本体时取消“去点击点移动”】====================
		is_moving_to_point = false
		velocity = Vector2.ZERO
		# ========================================================================
		
		animator.play("picked")
		await get_tree().create_timer(1).timeout
		animator.play("sit")
		
func spawn_hand(pos: Vector2):
	var hand = hand_scene.instantiate()
	get_tree().current_scene.add_child(hand)
	hand.global_position = pos

func spawn_heart():
	var heart = heart_scene.instantiate()
	get_tree().current_scene.add_child(heart)
	heart.global_position = $HeartPos.global_position

# ====================【新增：点击某个位置后让猫走过去】====================
func go_to_point(target_pos: Vector2):
	# ====================【修改：加入喝水流程互斥】====================
	if is_eating_food or is_going_to_eat or is_drinking_water or is_going_to_drink:
		return
	# ============================================================
	
	is_moving_to_point = true
	move_target_position = target_pos
	
	# 目标点限制在活动边界内
	move_target_position.x = clamp(move_target_position.x, walk_min_x, walk_max_x)
	move_target_position.y = clamp(move_target_position.y, walk_min_y, walk_max_y)
# ======================================================================

# ====================【保留原吃饭逻辑，不改主体，只补互斥】====================
func go_to_eat(target_pos: Vector2):
	print("收到目标点:", target_pos)
	# ====================【新增：吃饭时取消普通点击移动】====================
	is_moving_to_point = false
	# =================================================================
	
	# ====================【新增：避免和喝水流程冲突】====================
	is_going_to_drink = false
	is_drinking_water = false
	# ==============================================================
	
	is_going_to_eat = true
	is_eating_food = false
	food_target_position = target_pos
	
	if cat_collision:
		cat_collision.disabled = true


func start_eating_food():
	is_eating_food = true
	animator.play("eat")
	$eat.play()
	
	await get_tree().create_timer(eat_duration).timeout
	
	$eat.stop()
	is_eating_food = false
	
	if cat_collision:
		cat_collision.disabled = false
	
	emit_signal("eat_finished")
	change_state(State.IDLE)
# ===================================================================

# ====================【新增：喝水逻辑】====================
func go_to_drink(target_pos: Vector2):
	print("收到喝水目标点:", target_pos)
	
	# 喝水时取消普通点击移动
	is_moving_to_point = false
	
	# 避免和吃饭流程冲突
	is_going_to_eat = false
	is_eating_food = false
	
	is_going_to_drink = true
	is_drinking_water = false
	water_target_position = target_pos
	
	if cat_collision:
		cat_collision.disabled = true


func start_drinking_water():
	is_drinking_water = true
	
	# 你要求逻辑与喂食一致，所以这里仍然沿用 eat 动画和 eat 音效
	animator.play("eat")
	$drink.play()
	
	await get_tree().create_timer(drink_duration).timeout
	
	$drink.stop()
	is_drinking_water = false
	
	if cat_collision:
		cat_collision.disabled = false
	
	emit_signal("drink_finished")
	change_state(State.IDLE)
# ======================================================

func play_splash_roll() -> void:
	if not animator:
		return
	
	velocity = Vector2.ZERO
	if animator.sprite_frames.has_animation("roll"):
		animator.play("roll")
		await animator.animation_finished
	else:
		# 如果暂时没有 roll 动画，就退化成 picked 或 sit
		if animator.sprite_frames.has_animation("picked"):
			animator.play("picked")
			await get_tree().create_timer(1.0).timeout
	
	animator.play("sit")


# ======================
# 新增：普通散步辅助函数
# ======================
func _pick_random_walk_direction():
	# 以水平移动为主，但加入一点点上下随机
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-0.35, 0.35)
	var dir = Vector2(random_x, random_y)
	
	if dir.length() < 0.1:
		dir = Vector2(1, 0)
	
	walk_direction = dir.normalized()
	
	# 如果一开始方向就朝着边界外，立即修正
	_update_walk_direction_by_boundary()


func _update_walk_direction_by_boundary():
	# 靠近左右边界时，强制把 x 方向往回拉
	if global_position.x <= walk_min_x + 10.0 and walk_direction.x < 0:
		walk_direction.x = abs(walk_direction.x)
	elif global_position.x >= walk_max_x - 10.0 and walk_direction.x > 0:
		walk_direction.x = -abs(walk_direction.x)
	
	# 靠近上下边界时，强制把 y 方向往回拉
	if global_position.y <= walk_min_y + 10.0 and walk_direction.y < 0:
		walk_direction.y = abs(walk_direction.y)
	elif global_position.y >= walk_max_y - 10.0 and walk_direction.y > 0:
		walk_direction.y = -abs(walk_direction.y)
	
	if walk_direction.length() < 0.1:
		walk_direction = Vector2(1, 0)
	else:
		walk_direction = walk_direction.normalized()


func _clamp_walk_position():
	global_position.x = clamp(global_position.x, walk_min_x, walk_max_x)
	global_position.y = clamp(global_position.y, walk_min_y, walk_max_y)
