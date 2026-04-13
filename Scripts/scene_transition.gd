extends CanvasLayer

# 必须注册为 AutoLoad 单例，名称建议：PawTransition
# Project -> Project Settings -> AutoLoad -> 添加本场景或本脚本

@export var paw_texture: Texture2D

@export var columns: int = 9
@export var rows: int = 7
@export var paw_fill_ratio: float = 0.80

@export var wave_step_delay: float = 0.060
@export var intra_wave_jitter: float = 0.030

@export var stamp_in_time: float = 0.11
@export var stamp_settle_time: float = 0.09
@export var stamp_overshoot: float = 1.20
@export var paw_visible_duration: float = 0.25
@export var paw_fade_out_time: float = 0.18

@export var angle_left: float = -18.0
@export var angle_right: float = 18.0
@export var angle_jitter: float = 12.0
@export var pos_jitter: float = 5.0

@export var bg_color: Color = Color(1.0, 0.96, 0.98, 1.0)
@export var bg_fade_out_time: float = 0.35

@onready var color_rect: ColorRect = $ColorRect
@onready var prints: Node2D = $Prints

signal _all_paws_done

var _is_busy: bool = false
var _paw_tween_count: int = 0
var _spawn_finished: bool = false


func _ready() -> void:
	layer = 100
	visible = false

	color_rect.color = bg_color
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.offset_left = 0
	color_rect.offset_top = 0
	color_rect.offset_right = 0
	color_rect.offset_bottom = 0


func transition_to_scene(scene_path: String) -> void:
	if _is_busy:
		return
	if paw_texture == null:
		push_warning("PawTransition: paw_texture 尚未在 Inspector 中指定。")
		return

	_is_busy = true
	visible = true

	await _play_in()

	# 参考你提供的逻辑：入场动画播完后直接切场景
	get_tree().change_scene_to_file(scene_path)

	# 等新场景稳定
	await get_tree().process_frame
	await get_tree().process_frame

	# 切到新场景后立刻清掉猫爪，只保留纯背景
	_clear_prints()

	# 只把纯色背景淡出
	await _fade_bg_out()

	visible = false
	_is_busy = false


func _play_in() -> void:
	_clear_prints()
	_paw_tween_count = 0
	_spawn_finished = false

	# 先让背景淡入到完全不透明，保证切场景时屏幕已被盖住
	color_rect.modulate.a = 0.0
	var bg_tween := create_tween()
	bg_tween.tween_property(color_rect, "modulate:a", 1.0, 0.16)

	# 播放你原来那套猫爪扩散动画
	_spawn_paws_over_time()

	# 等所有猫爪动画结束
	await _all_paws_done


func _fade_bg_out() -> void:
	var bg_tween := create_tween()
	bg_tween.tween_property(color_rect, "modulate:a", 0.0, bg_fade_out_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await bg_tween.finished


func _spawn_paws_over_time() -> void:
	_paw_tween_count = 0
	_spawn_finished = false

	var view: Vector2 = get_viewport().get_visible_rect().size
	var cell_w: float = view.x / float(columns)
	var cell_h: float = view.y / float(rows)
	var paw_size: float = minf(cell_w, cell_h) * paw_fill_ratio
	var tex_size: Vector2 = paw_texture.get_size()
	var base_scale: float = paw_size / maxf(tex_size.x, tex_size.y)

	var cells: Array = []
	for col in range(columns):
		for row in range(rows):
			cells.append({
				"col": col,
				"row": row,
				"wave": col + row,
				"jitter": randf_range(0.0, intra_wave_jitter)
			})

	cells.sort_custom(func(a, b): return a["wave"] < b["wave"])

	var current_wave: int = -1
	var elapsed: float = 0.0

	for cell in cells:
		var wave_idx: int = cell["wave"]

		if wave_idx != current_wave:
			current_wave = wave_idx
			var target_t: float = wave_idx * wave_step_delay
			var wait_t: float = target_t - elapsed
			if wait_t > 0.001:
				await get_tree().create_timer(wait_t).timeout
				elapsed = target_t

		var paw := Sprite2D.new()
		paw.texture = paw_texture
		paw.centered = true
		paw.modulate.a = 0.0

		var cx: float = cell_w * cell["col"] + cell_w * 0.5
		var cy: float = cell_h * cell["row"] + cell_h * 0.5
		paw.position = Vector2(
			cx + randf_range(-pos_jitter, pos_jitter),
			cy + randf_range(-pos_jitter, pos_jitter)
		)

		var is_left: bool = (wave_idx % 2 == 0)
		var base_angle: float = angle_left if is_left else angle_right
		paw.rotation = deg_to_rad(base_angle + randf_range(-angle_jitter, angle_jitter))
		paw.scale = Vector2.ONE * base_scale * stamp_overshoot

		prints.add_child(paw)

		var tw := create_tween()

		if cell["jitter"] > 0.001:
			tw.tween_interval(cell["jitter"])

		tw.set_parallel(true)
		tw.tween_property(paw, "modulate:a", 1.0, stamp_in_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(paw, "scale", Vector2.ONE * base_scale * stamp_overshoot, stamp_in_time)

		tw.chain().set_parallel(true)
		tw.tween_property(paw, "scale", Vector2.ONE * base_scale, stamp_settle_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tw.chain().tween_interval(paw_visible_duration)

		tw.chain().tween_property(paw, "modulate:a", 0.0, paw_fade_out_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		_paw_tween_count += 1
		tw.finished.connect(_on_single_paw_tween_finished)

	_spawn_finished = true

	if _paw_tween_count == 0:
		_all_paws_done.emit()


func _on_single_paw_tween_finished() -> void:
	_paw_tween_count -= 1
	if _paw_tween_count <= 0 and _spawn_finished:
		_paw_tween_count = 0
		_all_paws_done.emit()


func _clear_prints() -> void:
	for child in prints.get_children():
		child.queue_free()
