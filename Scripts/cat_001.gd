extends CharacterBody2D

signal eat_finished

@export var splash_mode: bool = false

@export var move_speed : float = 50
@export var eat_speed : float = 250
@export var animator : AnimatedSprite2D

@export var hand_scene : PackedScene
@export var heart_scene : PackedScene

@onready var cat_collision = $CollisionShape2D

# ====================【新增：吃饭控制】====================
@export var eat_duration : float = 3.0
@export var food_arrive_distance : float = 20.0

var is_going_to_eat : bool = false
var is_eating_food : bool = false
var food_target_position : Vector2 = Vector2.ZERO
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
	# ====================【新增：去吃饭优先级最高】====================
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
			return
	
	if is_eating_food:
		velocity = Vector2.ZERO
		return
	# ==============================================================
	
	state_timer -= delta
	
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		
		State.WALK:
			move_and_slide()
		
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
			state_timer = randf_range(2, 5)
		
		State.WALK:
			animator.play("walk")
			# 随机方向
			var dir = -1 if randf() < 0.5 else 1
			velocity = Vector2(dir * move_speed, 0)
			animator.flip_h = dir < 0
			state_timer = randf_range(2, 4)
		
		State.SLEEP:
			animator.play("sleep")
			state_timer = randf_range(4, 8)


func decide_next_state():
	match current_state:
		State.IDLE:
			if randf() < 0.6:
				change_state(State.WALK)
			else:
				change_state(State.SLEEP)
		
		State.WALK:
			if randf() < 0.5:
				change_state(State.IDLE)
			else:
				change_state(State.SLEEP)
		
		State.SLEEP:
			change_state(State.IDLE)


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
		
		GameManager.intimacy += 1
		$AudioStreamPlayer.play()
		print(GameManager.intimacy)
		# 打断当前行为
		current_state = State.IDLE
		
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

# ====================【新增：外部调用，让猫去吃饭】====================
func go_to_eat(target_pos: Vector2):
	print("收到目标点:", target_pos)
	is_going_to_eat = true
	is_eating_food = false
	food_target_position = target_pos
	
	if cat_collision:
		cat_collision.disabled = true


func start_eating_food():
	is_eating_food = true
	
	# 到达后播放吃饭动画
	if animator.sprite_frames.has_animation("eat"):
		animator.play("eat")
	else:
		animator.play("sit")
	
	await get_tree().create_timer(eat_duration).timeout
	
	is_eating_food = false
	
	if cat_collision:
		cat_collision.disabled = false
	
	emit_signal("eat_finished")
	
	change_state(State.IDLE)
# ===================================================================
func play_splash_roll() -> void:
	if not animator:
		return
	
	velocity = Vector2.ZERO
	
	#if animator.sprite_frames.has_animation("roll"):
		#animator.play("roll")
		#await animator.animation_finished
	if animator.sprite_frames.has_animation("sleep"):
		animator.play("sleep")
		await animator.animation_finished
	else:
		# 如果暂时没有 roll 动画，就退化成 picked 或 sit
		if animator.sprite_frames.has_animation("picked"):
			animator.play("picked")
			await get_tree().create_timer(1.0).timeout
	
	animator.play("sit")
