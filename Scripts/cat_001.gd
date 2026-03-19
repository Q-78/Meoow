extends CharacterBody2D

@export var move_speed : float = 50
@export var animator : AnimatedSprite2D

enum State {
	IDLE,
	WALK,
	SLEEP
}

var current_state : State = State.IDLE
var state_timer : float = 0.0

func _ready() -> void:
	change_state(State.IDLE)


func _physics_process(delta: float) -> void:
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
		GameManager.intimacy += 1
		$AudioStreamPlayer.play()
		print(GameManager.intimacy)
		# 打断当前行为
		current_state = State.IDLE
		
		animator.play("picked")
		await get_tree().create_timer(1).timeout
		animator.play("sit")
