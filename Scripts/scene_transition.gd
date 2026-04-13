extends CanvasLayer

# 必须注册为 AutoLoad 单例，名称 PawTransition
# Project → Project Settings → AutoLoad → 添加本脚本

@export var paw_texture: Texture2D

@export var columns: int          = 9
@export var rows: int             = 7
@export var paw_fill_ratio: float = 0.80

@export var wave_step_delay: float   = 0.060
@export var intra_wave_jitter: float = 0.030

@export var stamp_in_time: float        = 0.11
@export var stamp_settle_time: float    = 0.09
@export var stamp_overshoot: float      = 1.20
@export var paw_visible_duration: float = 0.25
@export var paw_fade_out_time: float    = 0.18

@export var angle_left: float   = -18.0
@export var angle_right: float  =  18.0
@export var angle_jitter: float =  12.0
@export var pos_jitter: float   =   5.0

@export var use_bg: bool    = true
@export var bg_color: Color = Color(1.0, 0.96, 0.98, 1.0)

@onready var color_rect: ColorRect = $ColorRect
@onready var prints: Node2D        = $Prints

# 所有脚印动画全部真正结束后发出此信号
signal _all_paws_done

var _is_busy: bool = false
var _pending_scene: String = ""
var _paw_tween_count: int = 0   # 还在跑的 tween 数量

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
	_pending_scene = scene_path
	visible = true

	# 每次开始前先恢复背景透明，避免上次状态残留
	color_rect.modulate.a = 0.0

	# 启动逐帧生成脚印的协程
	_spawn_paws_over_time()

	# 等待所有脚印 tween 结束
	await _all_paws_done

	# 先让纯背景完全盖住屏幕
	if use_bg:
		color_rect.modulate.a = 1.0

	# 关键：先渲染这一帧，让“遮罩已盖住屏幕”这件事真正显示出来
	await get_tree().process_frame

	# 清理旧脚印，避免切场景时残留
	_clear_prints()

	# 这时再切场景，新场景不会提前露出来
	get_tree().change_scene_to_file(_pending_scene)

	# 等新场景完成初始化和首帧绘制
	await get_tree().process_frame
	await get_tree().process_frame

	# 再把遮罩淡出去
	if use_bg:
		var tw := create_tween()
		tw.tween_property(color_rect, "modulate:a", 0.0, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tw.finished

	visible = false
	_is_busy = false

# ────────────────────────────────────────────────────────────────
# 协程：按波次逐个真正创建脚印，每个脚印的 tween finished 时计数
# 当计数归零且所有脚印已创建完毕，发出 _all_paws_done
# ────────────────────────────────────────────────────────────────
func _spawn_paws_over_time() -> void:
	_paw_tween_count = 0

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

	var spawned: int = 0
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
		spawned += 1
		var _s := spawned
		tw.finished.connect(func():
			_paw_tween_count -= 1
			if _paw_tween_count == 0:
				_all_paws_done.emit()
		)

func _clear_prints() -> void:
	for child in prints.get_children():
		child.queue_free()
