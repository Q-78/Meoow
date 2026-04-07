extends Node2D

@export_file("*.tscn") var next_scene_path: String = "res://Scenes/playground.tscn"

# =========================
# 动画参数（已优化）
# =========================
@export var jump_duration: float = 0.8      # 整次跳跃更长，滞空更自然
@export var jump_height: float = 130.0      # 跳得更高
@export var stay_time: float = 0.16         # 每次落地后停顿
@export var end_hold_time: float = 0.8      # 结尾停留时间
@export var sleep_time: float = 1.5         # 到 M 后播放 sleep 动画的时长
@export var m_final_texture: Texture2D      # 修改位置1：小猫消失时，M 切换成的新图片

@onready var cat = $cat001

@onready var letter_m = $Letters/M
@onready var letter_e = $Letters/e
@onready var letter_o1 = $Letters/O1
@onready var letter_o2 = $Letters/O2
@onready var letter_w = $Letters/W

var jump_targets: Array = []

var cat_base_scale: Vector2
var letter_base_scales: Dictionary = {}

func _ready() -> void:
	# 记录猫原始缩放
	cat_base_scale = cat.scale

	# 记录字母原始缩放
	letter_base_scales[letter_m] = letter_m.scale
	letter_base_scales[letter_e] = letter_e.scale
	letter_base_scales[letter_o1] = letter_o1.scale
	letter_base_scales[letter_o2] = letter_o2.scale
	letter_base_scales[letter_w] = letter_w.scale

	# 所有字母先隐藏
	letter_m.visible = false
	letter_e.visible = false
	letter_o1.visible = false
	letter_o2.visible = false
	letter_w.visible = false

	# 小猫从右侧屏幕外出场
	cat.position.x += 300

	# 跳跃顺序：W -> O2 -> O1 -> e -> M
	jump_targets = [
		{"node": letter_w, "pos": $Letters/W/LandPoint.global_position},
		{"node": letter_o2, "pos": $Letters/O2/LandPoint.global_position},
		{"node": letter_o1, "pos": $Letters/O1/LandPoint.global_position},
		{"node": letter_e, "pos": $Letters/e/LandPoint.global_position},
		{"node": letter_m, "pos": $Letters/M/LandPoint.global_position},
	]

	await play_logo_animation()
	await play_cat_sleep_then_wait()
	await fade_out_cat()

	await get_tree().create_timer(end_hold_time).timeout

	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)


# =========================
# 主动画流程
# 猫离开当前字母后，当前字母才出现
# =========================
func play_logo_animation() -> void:
	# 先跳到第一个字母 W
	await jump_to(jump_targets[0]["pos"])
	await squash_effect()
	await get_tree().create_timer(stay_time).timeout

	# 逐个向左跳
	for i in range(jump_targets.size() - 1):
		var current_target = jump_targets[i]
		var next_target = jump_targets[i + 1]

		# 先朝下一个字母方向斜着起跳
		var peak_pos = await jump_leave_current(next_target["pos"])

		# 猫已经离开当前字母，此时字母出现
		await show_letter(current_target["node"])

		# 再从空中落到下一个字母
		await jump_land_to(peak_pos, next_target["pos"])
		await squash_effect()
		await get_tree().create_timer(stay_time).timeout

	# 最后一个 M：猫已经落到 M，再显示 M
	await show_letter(jump_targets[-1]["node"])
	await get_tree().create_timer(0.12).timeout


# =========================
# 初始：从右侧跳到第一个字母
# =========================
func jump_to(target_pos: Vector2) -> void:
	var start = cat.global_position
	var mid = (start + target_pos) / 2.0
	mid.y -= jump_height

	var t1 = create_tween()
	t1.tween_property(cat, "global_position", mid, jump_duration * 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	await t1.finished

	await get_tree().create_timer(0.04).timeout

	var t2 = create_tween()
	t2.tween_property(cat, "global_position", target_pos, jump_duration * 0.6) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	await t2.finished


# =========================
# 从当前字母斜着起跳离开
# =========================
func jump_leave_current(next_target_pos: Vector2) -> Vector2:
	var start = cat.global_position
	var dir_x = next_target_pos.x - start.x

	var peak_x = start.x + dir_x * 0.28
	var peak_y = start.y - jump_height
	var peak = Vector2(peak_x, peak_y)

	var t = create_tween()
	t.tween_property(cat, "global_position", peak, jump_duration * 0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	await t.finished

	await get_tree().create_timer(0.04).timeout

	return peak


# =========================
# 从空中落到下一个字母
# =========================
func jump_land_to(from_pos: Vector2, target_pos: Vector2) -> void:
	cat.global_position = from_pos

	var t = create_tween()
	t.tween_property(cat, "global_position", target_pos, jump_duration * 0.6) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN)
	await t.finished


# =========================
# 字母出现动画
# =========================
func show_letter(letter) -> void:
	var base_scale: Vector2 = letter_base_scales[letter]

	letter.visible = true
	letter.scale = base_scale * 0.9

	var t = create_tween()
	t.tween_property(letter, "scale", base_scale * 1.08, 0.08)
	t.tween_property(letter, "scale", base_scale, 0.08)
	await t.finished


# =========================
# 切换 M 的图片
# =========================
func change_m_texture() -> void:
	if not letter_m:
		return
	
	if letter_m is Sprite2D and m_final_texture:
		letter_m.texture = m_final_texture


# =========================
# 到 M 后播放 sleep 动画一段时间
# =========================
func play_cat_sleep_then_wait() -> void:
	if not cat:
		return

	if cat.has_method("play_sleep"):
		cat.play_sleep()
	elif cat.has_node("AnimatedSprite2D"):
		var anim = cat.get_node("AnimatedSprite2D")
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("sleep"):
			anim.play("sleep")

	await get_tree().create_timer(sleep_time).timeout


# =========================
# 落地压缩，更柔和自然
# =========================
func squash_effect() -> void:
	cat.scale = Vector2(cat_base_scale.x * 1.08, cat_base_scale.y * 0.92)

	var t = create_tween()
	t.tween_property(cat, "scale", Vector2(cat_base_scale.x * 0.97, cat_base_scale.y * 1.03), 0.05)
	t.tween_property(cat, "scale", cat_base_scale, 0.07)
	await t.finished


# =========================
# 最后在 M 位置淡出
# =========================
func fade_out_cat() -> void:
	# 修改位置3：小猫开始消失时，同时切换 M 的图片
	change_m_texture()

	var t = create_tween()
	t.tween_property(cat, "scale", cat_base_scale * 0.85, 0.12)
	t.parallel().tween_property(cat, "modulate:a", 0.0, 0.18)
	await t.finished
	cat.visible = false
