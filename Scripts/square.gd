extends Node2D

const CAT_REACH_SCALE: Vector2 = Vector2(7.5, 6.35)
const BUTTERFLY_TEXTURES := [
	preload("res://Assets/外部素材1/Assets/Butterfly/Butterfly-7.png"),
	preload("res://Assets/外部素材1/Assets/Butterfly/Butterfly-8.png"),
	preload("res://Assets/外部素材1/Assets/Butterfly/Butterfly-9.png"),
	preload("res://Assets/外部素材1/Assets/Butterfly/Butterfly-10.png"),
	preload("res://Assets/外部素材1/Assets/Butterfly/Butterfly-11.png"),
	preload("res://Assets/外部素材1/Assets/Butterfly/Butterfly-12.png")
]
const BUTTERFLY_BASE_FACE_LEFT := [true, true, false, false, true, false]
const CATCH_SIT_FRAMES = preload("res://Assets/Cat001/cat001_sit_catch_frames.tres")
const CATCH_STAND_FRAMES = preload("res://Assets/Cat001/cat001_stand_catch_frames.tres")

const BUTTERFLY_SCALE: Vector2 = Vector2(1.1, 1.1)
const BUTTERFLY_MIN_COUNT: int = 1
const BUTTERFLY_MAX_COUNT: int = 2
const BUTTERFLY_MIN_X: float = 130.0
const BUTTERFLY_MAX_X: float = 590.0
const BUTTERFLY_MIN_Y: float = 650.0
const BUTTERFLY_MAX_Y: float = 820.0
const BUTTERFLY_HORIZONTAL_SPEED_MIN: float = 24.0
const BUTTERFLY_HORIZONTAL_SPEED_MAX: float = 38.0
const BUTTERFLY_VERTICAL_AMPLITUDE_MIN: float = 5.0
const BUTTERFLY_VERTICAL_AMPLITUDE_MAX: float = 16.0
const BUTTERFLY_VERTICAL_SPEED_MIN: float = 0.7
const BUTTERFLY_VERTICAL_SPEED_MAX: float = 1.25
const BUTTERFLY_PAUSE_INTERVAL: float = 10.0
const BUTTERFLY_PAUSE_DURATION_MIN: float = 1.0
const BUTTERFLY_PAUSE_DURATION_MAX: float = 2.0
const CHASE_INTERVAL_MIN: float = 36.0
const CHASE_INTERVAL_MAX: float = 44.0
const TARGET_SWITCH_MARGIN: float = 36.0

@onready var cat_click: Area2D = $CatClick
@onready var cat: AnimatedSprite2D = $CatClick/Cat
@onready var to_map_button: Button = $to_map

var home_position: Vector2
var chase_timer: Timer
var butterflies_root: Node2D
var butterfly_nodes: Array[Sprite2D] = []
var butterfly_data: Dictionary = {}
var is_chasing_butterfly: bool = false
var base_cat_scale: Vector2
var default_cat_frames: SpriteFrames
var locked_butterfly: Sprite2D = null
var locked_flip_h: bool = false

func _ready() -> void:
	randomize()
	if not to_map_button.pressed.is_connected(_on_to_map_pressed):
		to_map_button.pressed.connect(_on_to_map_pressed)
	default_cat_frames = cat.sprite_frames
	home_position = cat_click.position
	base_cat_scale = cat.scale
	_setup_butterfly_root()
	_setup_chase_timer()
	_load_or_create_butterflies()
	cat.play("sit")
	_update_locked_target_and_facing(true)

func _process(delta: float) -> void:
	if is_chasing_butterfly:
		cat.flip_h = locked_flip_h
	else:
		_update_locked_target_and_facing()
	_update_butterflies(delta)
	if chase_timer != null and not chase_timer.is_stopped():
		GameManager.square_chase_time_left = max(chase_timer.time_left, 0.1)

func _setup_butterfly_root() -> void:
	butterflies_root = Node2D.new()
	butterflies_root.name = "Butterflies"
	add_child(butterflies_root)

func _setup_chase_timer() -> void:
	chase_timer = Timer.new()
	chase_timer.one_shot = true
	add_child(chase_timer)
	chase_timer.timeout.connect(_on_chase_timer_timeout)

func _load_or_create_butterflies() -> void:
	if GameManager.persist_square_butterfly and not GameManager.square_butterfly_state.is_empty():
		_restore_butterfly_state()
		_schedule_next_chase(max(GameManager.square_chase_time_left, 0.5))
	else:
		_create_initial_butterflies()
		_schedule_next_chase()

func _create_initial_butterflies() -> void:
	_clear_existing_butterflies()
	var butterfly_count: int = randi_range(BUTTERFLY_MIN_COUNT, BUTTERFLY_MAX_COUNT)
	for i in range(butterfly_count):
		_spawn_butterfly(_make_random_spawn_position(i))
	_save_square_state()

func _spawn_butterfly(spawn_position: Vector2) -> Sprite2D:
	var butterfly := Sprite2D.new()
	butterfly.name = "Butterfly_%d" % butterfly_nodes.size()
	var texture_index: int = randi() % BUTTERFLY_TEXTURES.size()
	butterfly.texture = BUTTERFLY_TEXTURES[texture_index]
	butterfly.position = spawn_position
	butterfly.scale = BUTTERFLY_SCALE
	butterfly.z_index = 3
	butterflies_root.add_child(butterfly)
	butterfly_nodes.append(butterfly)
	var state := _make_butterfly_motion_state(texture_index, spawn_position)
	butterfly_data[butterfly] = state
	_apply_butterfly_facing(butterfly, texture_index, float(state.get("direction", 1.0)))
	return butterfly

func _make_butterfly_motion_state(texture_index: int, spawn_position: Vector2) -> Dictionary:
	var direction: float = -1.0 if randf() < 0.5 else 1.0
	var pause_interval: float = randf_range(8.0, 13.0)

	return {
		"texture_index": texture_index,
		"base_position": spawn_position,
		"horizontal_speed": randf_range(BUTTERFLY_HORIZONTAL_SPEED_MIN, BUTTERFLY_HORIZONTAL_SPEED_MAX),
		"direction": direction,
		"vertical_amplitude": randf_range(BUTTERFLY_VERTICAL_AMPLITUDE_MIN, BUTTERFLY_VERTICAL_AMPLITUDE_MAX),
		"vertical_speed": randf_range(BUTTERFLY_VERTICAL_SPEED_MIN, BUTTERFLY_VERTICAL_SPEED_MAX),
		"vertical_phase": randf_range(0.0, TAU),

		# ⭐ 防同步关键
		"pause_timer": randf_range(2.0, pause_interval),
		"pause_duration": 0.0,
		"pause_interval": pause_interval,

		"fleeing": false
	}

func _apply_butterfly_facing(butterfly: Sprite2D, texture_index: int, direction: float) -> void:
	var moving_left: bool = direction < 0.0
	var base_face_left: bool = bool(BUTTERFLY_BASE_FACE_LEFT[clamp(texture_index, 0, BUTTERFLY_BASE_FACE_LEFT.size() - 1)])
	butterfly.flip_h = moving_left != base_face_left

func _restore_butterfly_state() -> void:
	_clear_existing_butterflies()
	var saved_list: Array = GameManager.square_butterfly_state.get("butterflies", [])
	for entry in saved_list:
		var butterfly := Sprite2D.new()
		butterfly.name = "Butterfly_%d" % butterfly_nodes.size()
		var texture_index: int = clamp(int(entry.get("texture_index", 0)), 0, BUTTERFLY_TEXTURES.size() - 1)
		butterfly.texture = BUTTERFLY_TEXTURES[texture_index]
		butterfly.position = entry.get("position", _make_random_spawn_position(butterfly_nodes.size()))
		butterfly.scale = BUTTERFLY_SCALE
		butterfly.z_index = 3
		butterfly.visible = bool(entry.get("visible", true))
		butterfly.modulate.a = float(entry.get("alpha", 1.0))
		butterflies_root.add_child(butterfly)
		butterfly_nodes.append(butterfly)
		var state := {
			"texture_index": texture_index,
			"base_position": entry.get("base_position", butterfly.position),
			"horizontal_speed": float(entry.get("horizontal_speed", randf_range(BUTTERFLY_HORIZONTAL_SPEED_MIN, BUTTERFLY_HORIZONTAL_SPEED_MAX))),
			"direction": float(entry.get("direction", 1.0)),
			"vertical_amplitude": float(entry.get("vertical_amplitude", randf_range(BUTTERFLY_VERTICAL_AMPLITUDE_MIN, BUTTERFLY_VERTICAL_AMPLITUDE_MAX))),
			"vertical_speed": float(entry.get("vertical_speed", randf_range(BUTTERFLY_VERTICAL_SPEED_MIN, BUTTERFLY_VERTICAL_SPEED_MAX))),
			"vertical_phase": float(entry.get("vertical_phase", randf_range(0.0, TAU))),
			"pause_timer": float(entry.get("pause_timer", randf_range(3.0, BUTTERFLY_PAUSE_INTERVAL))),
			"pause_duration": float(entry.get("pause_duration", 0.0)),
			"pause_interval": float(entry.get("pause_interval", BUTTERFLY_PAUSE_INTERVAL)),
			"fleeing": false
		}
		butterfly_data[butterfly] = state
		_apply_butterfly_facing(butterfly, texture_index, float(state.get("direction", 1.0)))
	if butterfly_nodes.is_empty():
		_create_initial_butterflies()

func _clear_existing_butterflies() -> void:
	for butterfly in butterfly_nodes:
		if is_instance_valid(butterfly):
			butterfly.queue_free()
	butterfly_nodes.clear()
	butterfly_data.clear()
	locked_butterfly = null

func _update_butterflies(delta: float) -> void:
	for butterfly in butterfly_nodes:
		if not is_instance_valid(butterfly) or not butterfly.visible:
			continue
		var state: Dictionary = butterfly_data.get(butterfly, {})
		if state.is_empty():
			continue
		if bool(state.get("fleeing", false)):
			continue

		var pause_duration: float = float(state.get("pause_duration", 0.0))
		if pause_duration > 0.0:
			pause_duration -= delta
			state["pause_duration"] = max(pause_duration, 0.0)
			if pause_duration <= 0.0:
				state["pause_timer"] = float(state.get("pause_interval", BUTTERFLY_PAUSE_INTERVAL))
			butterfly_data[butterfly] = state
			continue

		var pause_timer: float = float(state.get("pause_timer", BUTTERFLY_PAUSE_INTERVAL)) - delta
		if pause_timer <= 0.0:
			state["pause_duration"] = randf_range(BUTTERFLY_PAUSE_DURATION_MIN, BUTTERFLY_PAUSE_DURATION_MAX)
			state["pause_timer"] = 0.0
			butterfly_data[butterfly] = state
			continue
		state["pause_timer"] = pause_timer

		var base_position: Vector2 = state.get("base_position", butterfly.position)
		var direction: float = float(state.get("direction", 1.0))
		var horizontal_speed: float = float(state.get("horizontal_speed", 30.0))
		base_position.x += direction * horizontal_speed * delta
		if base_position.x <= BUTTERFLY_MIN_X:
			base_position.x = BUTTERFLY_MIN_X
			direction = 1.0
		elif base_position.x >= BUTTERFLY_MAX_X:
			base_position.x = BUTTERFLY_MAX_X
			direction = -1.0

		var phase: float = float(state.get("vertical_phase", 0.0)) + delta * float(state.get("vertical_speed", 1.0))
		var amplitude: float = float(state.get("vertical_amplitude", 10.0))
		var y_offset: float = sin(phase) * amplitude
		var final_y: float = clamp(base_position.y + y_offset, BUTTERFLY_MIN_Y, BUTTERFLY_MAX_Y)

		butterfly.position = Vector2(base_position.x, final_y)
		state["base_position"] = Vector2(base_position.x, clamp(base_position.y, BUTTERFLY_MIN_Y, BUTTERFLY_MAX_Y))
		state["vertical_phase"] = phase
		state["direction"] = direction
		butterfly_data[butterfly] = state
		_apply_butterfly_facing(butterfly, int(state.get("texture_index", 0)), direction)

func _update_locked_target_and_facing(force_refresh: bool = false) -> void:
	var next_target: Sprite2D = _get_locked_or_nearest_butterfly(cat_click.position, force_refresh)
	if next_target == null:
		locked_butterfly = null
		return
	locked_butterfly = next_target
	locked_flip_h = next_target.position.x > cat_click.position.x
	cat.flip_h = locked_flip_h

func _get_locked_or_nearest_butterfly(from_position: Vector2, force_refresh: bool = false) -> Sprite2D:
	var nearest: Sprite2D = _get_nearest_butterfly(from_position)
	if nearest == null:
		return null
	if force_refresh:
		return nearest
	if locked_butterfly == null or not is_instance_valid(locked_butterfly) or not locked_butterfly.visible:
		return nearest
	if locked_butterfly == nearest:
		return locked_butterfly

	var current_distance: float = from_position.distance_to(locked_butterfly.position)
	var new_distance: float = from_position.distance_to(nearest.position)
	if new_distance + TARGET_SWITCH_MARGIN < current_distance:
		return nearest
	return locked_butterfly

func _make_random_spawn_position(index: int = 0) -> Vector2:
	var tries: int = 24
	while tries > 0:
		var candidate := Vector2(randf_range(BUTTERFLY_MIN_X, BUTTERFLY_MAX_X), randf_range(BUTTERFLY_MIN_Y, BUTTERFLY_MAX_Y))
		var ok: bool = true
		for butterfly in butterfly_nodes:
			if is_instance_valid(butterfly) and butterfly.visible and butterfly.position.distance_to(candidate) < 120.0:
				ok = false
				break
		if ok:
			return candidate
		tries -= 1
	return Vector2(randf_range(BUTTERFLY_MIN_X, BUTTERFLY_MAX_X), randf_range(BUTTERFLY_MIN_Y, BUTTERFLY_MAX_Y))

func _schedule_next_chase(forced_wait: float = -1.0) -> void:
	if chase_timer == null:
		return
	chase_timer.wait_time = forced_wait if forced_wait > 0.0 else randf_range(CHASE_INTERVAL_MIN, CHASE_INTERVAL_MAX)
	chase_timer.start()
	GameManager.square_chase_time_left = chase_timer.time_left

func _on_chase_timer_timeout() -> void:
	if is_chasing_butterfly:
		_schedule_next_chase()
		return
	var target: Sprite2D = _get_locked_or_nearest_butterfly(cat_click.position, true)
	if target == null:
		_schedule_next_chase()
		return
	await _play_butterfly_chase(target)
	_schedule_next_chase()

func _play_butterfly_chase(target_butterfly: Sprite2D) -> void:
	if target_butterfly == null or not is_instance_valid(target_butterfly):
		return

	is_chasing_butterfly = true
	locked_butterfly = target_butterfly
	locked_flip_h = target_butterfly.position.x > cat_click.position.x
	cat.flip_h = locked_flip_h

	var data: Dictionary = butterfly_data.get(target_butterfly, {})
	data["fleeing"] = true
	butterfly_data[target_butterfly] = data
	var butterfly_position: Vector2 = target_butterfly.position

	cat.play("walk")

	var chase_target := Vector2(
		clamp(butterfly_position.x + (72.0 if butterfly_position.x < home_position.x else -72.0), 105.0, 615.0),
		clamp(butterfly_position.y + 112.0, 760.0, 940.0)
	)

	var run_tween := create_tween()
	run_tween.tween_property(cat_click, "position", chase_target, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await run_tween.finished

	await _play_catch_attempt_pose()

	var flee_offset_x: float = randf_range(120.0, 190.0) * (-1.0 if cat.flip_h else 1.0)
	var flee_target := Vector2(
		clamp(target_butterfly.position.x + flee_offset_x, BUTTERFLY_MIN_X - 60.0, BUTTERFLY_MAX_X + 80.0),
		clamp(target_butterfly.position.y - randf_range(45.0, 95.0), BUTTERFLY_MIN_Y - 40.0, BUTTERFLY_MAX_Y)
	)
	var butterfly_escape_tween := create_tween()
	butterfly_escape_tween.parallel().tween_property(target_butterfly, "position", flee_target, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	butterfly_escape_tween.parallel().tween_property(target_butterfly, "modulate:a", 0.0, 0.55)
	await butterfly_escape_tween.finished

	target_butterfly.visible = false
	cat.play("sit")
	cat.scale = base_cat_scale
	await get_tree().create_timer(0.18).timeout

	var return_tween := create_tween()
	return_tween.tween_property(cat_click, "position", home_position, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await return_tween.finished

	_replace_failed_butterfly(target_butterfly)
	is_chasing_butterfly = false
	_update_locked_target_and_facing(true)
	cat.play("sit")
	_save_square_state()

func _play_catch_attempt_pose() -> void:
	var catch_frames: SpriteFrames = CATCH_SIT_FRAMES if randf() < 0.5 else CATCH_STAND_FRAMES
	if catch_frames == null or not catch_frames.has_animation("catch"):
		var reach_tween := create_tween()
		reach_tween.tween_property(cat, "scale", CAT_REACH_SCALE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		reach_tween.tween_property(cat, "scale", base_cat_scale, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await reach_tween.finished
		return

	var original_frames: SpriteFrames = default_cat_frames
	cat.sprite_frames = catch_frames
	cat.scale = base_cat_scale
	cat.play("catch")
	await cat.animation_finished
	cat.sprite_frames = original_frames
	cat.scale = base_cat_scale
	cat.flip_h = locked_flip_h
	cat.play("sit")

func _replace_failed_butterfly(old_butterfly: Sprite2D) -> void:
	if butterfly_nodes.has(old_butterfly):
		butterfly_nodes.erase(old_butterfly)
	if butterfly_data.has(old_butterfly):
		butterfly_data.erase(old_butterfly)
	if locked_butterfly == old_butterfly:
		locked_butterfly = null
	if is_instance_valid(old_butterfly):
		old_butterfly.queue_free()

	if butterfly_nodes.size() < BUTTERFLY_MIN_COUNT:
		_spawn_butterfly(_make_random_spawn_position())
	elif butterfly_nodes.size() < BUTTERFLY_MAX_COUNT and randf() < 0.35:
		_spawn_butterfly(_make_random_spawn_position())

	for butterfly in butterfly_nodes:
		if is_instance_valid(butterfly):
			butterfly.modulate.a = 1.0
			butterfly.visible = true

func _get_nearest_butterfly(from_position: Vector2) -> Sprite2D:
	var nearest: Sprite2D = null
	var best_distance: float = INF
	for butterfly in butterfly_nodes:
		if not is_instance_valid(butterfly) or not butterfly.visible:
			continue
		var dist: float = from_position.distance_to(butterfly.position)
		if dist < best_distance:
			best_distance = dist
			nearest = butterfly
	return nearest

func _save_square_state() -> void:
	var saved_butterflies: Array = []
	for butterfly in butterfly_nodes:
		if not is_instance_valid(butterfly) or not butterfly.visible:
			continue
		var state: Dictionary = butterfly_data.get(butterfly, {})
		saved_butterflies.append({
			"texture_index": int(state.get("texture_index", 0)),
			"position": butterfly.position,
			"base_position": state.get("base_position", butterfly.position),
			"visible": butterfly.visible,
			"alpha": butterfly.modulate.a,
			"horizontal_speed": state.get("horizontal_speed", 30.0),
			"direction": state.get("direction", 1.0),
			"vertical_amplitude": state.get("vertical_amplitude", 10.0),
			"vertical_speed": state.get("vertical_speed", 1.0),
			"vertical_phase": state.get("vertical_phase", 0.0),
			"pause_timer": state.get("pause_timer", BUTTERFLY_PAUSE_INTERVAL),
			"pause_duration": state.get("pause_duration", 0.0),
			"pause_interval": state.get("pause_interval", BUTTERFLY_PAUSE_INTERVAL)
		})
	GameManager.square_butterfly_state = {
		"butterflies": saved_butterflies
	}
	if chase_timer != null and not chase_timer.is_stopped():
		GameManager.square_chase_time_left = max(chase_timer.time_left, 0.5)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if GameManager.persist_square_butterfly:
			_save_square_state()

func _on_cat_click_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameManager.persist_square_butterfly = true
		_save_square_state()
		get_tree().change_scene_to_file("res://Scenes/square_zoom.tscn")

func _on_to_map_pressed() -> void:
	var next_scene := "res://Scenes/map.tscn"
	GameManager.clear_square_butterfly_state()
	PawTransition.transition_to_scene(next_scene)
	#get_tree().change_scene_to_file("res://Scenes/map.tscn")
