extends Control

@onready var background_image: TextureRect = $BackgroundImage
@onready var title_label: Label = $TitleLabel
@onready var cat_image: TextureRect = $CatImage
@onready var cat_today_panel: Panel = $CatTodayPanel
@onready var cat_today_label: RichTextLabel = $CatTodayPanel/CatTodayLabel
@onready var luck_advice_panel: Panel = $LuckAdvicePanel
@onready var luck_advice_label: RichTextLabel = $LuckAdvicePanel/LuckAdviceLabel
@onready var status_label: Label = $StatusLabel
@onready var push_button: Button = $PushButton
@onready var to_map_button: Button = $to_map

@onready var agent_request: HTTPRequest = $AgentRequest
@onready var image_request: HTTPRequest = $ImageRequest


@export var api_base_url: String = "https://agent.hit.edu.cn/api/proxy/api/v1"
@export var api_key: String = "d862c55g77ds2k2dggs0"
@export var user_id: String = "godot_user_001"
@export var daily_query: String = "每日推送"

@export var background_texture: Texture2D

var app_conversation_id: String = ""
var waiting_response: bool = false
var pending_image_url: String = ""


enum RequestStep {
	NONE,
	CREATE_CONVERSATION,
	DAILY_PUSH
}

var current_step: RequestStep = RequestStep.NONE


func _ready() -> void:
	SceneMemory.set_last_scene(scene_file_path)

	_init_absolute_layout()
	_init_ui()
	_init_visual_style()

	if not push_button.pressed.is_connected(_on_push_button_pressed):
		push_button.pressed.connect(_on_push_button_pressed)

	if not to_map_button.pressed.is_connected(_on_to_map_pressed):
		to_map_button.pressed.connect(_on_to_map_pressed)

	if not agent_request.request_completed.is_connected(_on_agent_request_completed):
		agent_request.request_completed.connect(_on_agent_request_completed)

	if not image_request.request_completed.is_connected(_on_image_request_completed):
		image_request.request_completed.connect(_on_image_request_completed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_EXIT_TREE:
		SceneMemory.set_last_scene(scene_file_path)


# =========================================================
# 不用容器时，手动设置位置和大小
# =========================================================

func _init_absolute_layout() -> void:
	var screen_size: Vector2 = get_viewport_rect().size

	var content_width: float = min(screen_size.x - 96.0, 680.0)
	var left: float = (screen_size.x - content_width) / 2.0

	background_image.position = Vector2.ZERO
	background_image.size = screen_size

	title_label.position = Vector2(0, 38)
	title_label.size = Vector2(screen_size.x, 48)

	# 图片区域：略微上移，宽度更舒服
	cat_image.position = Vector2(left + 28, 118)
	cat_image.size = Vector2(content_width - 56, 300)

	# 第一张卡片：更紧凑、更靠近图片
	cat_today_panel.position = Vector2(left, 468)
	cat_today_panel.size = Vector2(content_width, 210)

	cat_today_label.position = Vector2(26, 22)
	cat_today_label.size = cat_today_panel.size - Vector2(52, 44)

	# 第二张卡片
	luck_advice_panel.position = Vector2(left, 716)
	luck_advice_panel.size = Vector2(content_width, 210)

	luck_advice_label.position = Vector2(26, 22)
	luck_advice_label.size = luck_advice_panel.size - Vector2(52, 44)

	# 状态提示
	status_label.position = Vector2(left, 962)
	status_label.size = Vector2(content_width, 38)

	# 主按钮：居中，宽度不要太满
	var button_width: float = min(content_width - 120.0, 520.0)
	push_button.position = Vector2((screen_size.x - button_width) / 2.0, 1040)
	push_button.size = Vector2(button_width, 72)

	# 返回图标位置保持你现在满意的位置，不改
	to_map_button.position = Vector2(left + content_width - 660, 1200)
	to_map_button.size = Vector2(70, 70)


func _init_ui() -> void:
	title_label.text = "今日推送"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	cat_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	cat_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	cat_today_label.bbcode_enabled = true
	luck_advice_label.bbcode_enabled = true

	cat_today_label.scroll_active = true
	luck_advice_label.scroll_active = true

	cat_today_label.text = "[center][color=#AFAFAF]还没有今日推送喵[/color][/center]"
	luck_advice_label.text = "[center][color=#AFAFAF]点击按钮获取今日运势建议[/color][/center]"

	status_label.text = "点击按钮，让校猫看看今天的运势吧"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	push_button.text = "获取今日推送"

	# 返回地图按钮只保留图标
	to_map_button.text = ""
	to_map_button.tooltip_text = "返回地图"
	to_map_button.flat = true
	to_map_button.expand_icon = true


func _init_visual_style() -> void:
	# 背景图设置
	background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if background_texture != null:
		background_image.texture = background_texture

	# 标题
	title_label.add_theme_color_override("font_color", Color("#FFFFFF"))
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.22))

	# 状态文字
	status_label.add_theme_color_override("font_color", Color("#F0F0F0"))
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_constant_override("outline_size", 1)
	status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.18))

	_apply_panel_style(cat_today_panel)
	_apply_panel_style(luck_advice_panel)

	cat_today_label.add_theme_color_override("default_color", Color("#F7F7F7"))
	luck_advice_label.add_theme_color_override("default_color", Color("#F7F7F7"))

	_apply_main_button_style(push_button)
	_apply_icon_button_style(to_map_button)


func _apply_panel_style(panel: Panel) -> void:
	var style := StyleBoxFlat.new()

	style.bg_color = Color("#2B2B2B")

	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.075)

	style.shadow_color = Color(0, 0, 0, 0.26)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 5)

	panel.add_theme_stylebox_override("panel", style)


func _apply_main_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color("#FFFFFF"))
	button.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	button.add_theme_color_override("font_pressed_color", Color("#EDEDED"))
	button.add_theme_color_override("font_disabled_color", Color("#999999"))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#292929")
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(1, 1, 1, 0.08)
	normal.shadow_color = Color(0, 0, 0, 0.22)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 4)

	var hover := normal.duplicate()
	hover.bg_color = Color("#363636")

	var pressed := normal.duplicate()
	pressed.bg_color = Color("#202020")
	pressed.shadow_size = 3
	pressed.shadow_offset = Vector2(0, 1)

	var disabled := normal.duplicate()
	disabled.bg_color = Color("#252525")
	disabled.shadow_size = 0

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _apply_icon_button_style(button: Button) -> void:
	button.text = ""
	button.flat = true
	button.expand_icon = true

	button.add_theme_color_override("icon_normal_color", Color("#FFFFFF"))
	button.add_theme_color_override("icon_hover_color", Color("#FFFFFF"))
	button.add_theme_color_override("icon_pressed_color", Color("#DDDDDD"))

	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)


func _on_push_button_pressed() -> void:
	if waiting_response:
		return

	_start_loading_ui()

	if app_conversation_id == "":
		_create_conversation()
	else:
		_send_daily_push()


func _create_conversation() -> void:
	current_step = RequestStep.CREATE_CONVERSATION

	var url: String = _join_url(api_base_url, "create_conversation")

	var headers: Array[String] = [
		"Apikey: " + api_key,
		"Content-Type: application/json"
	]

	var body_dict = {
		"UserID": user_id,
		"Inputs": {}
	}

	var json_body: String = JSON.stringify(body_dict)

	print("================ 创建每日推送会话 ================")
	print("url: ", url)
	print("UserID: ", user_id)
	print("json_body: ", json_body)
	print("==============================================")

	var err: int = agent_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if err != OK:
		_show_error("创建会话请求发送失败，错误码：" + str(err))


func _send_daily_push() -> void:
	current_step = RequestStep.DAILY_PUSH

	var url: String = _join_url(api_base_url, "chat_query_v2")

	var headers: Array[String] = [
		"Apikey: " + api_key,
		"Content-Type: application/json"
	]

	var body_dict = {
		"UserID": user_id,
		"AppConversationID": app_conversation_id,
		"Query": daily_query,
		"ResponseMode": "blocking"
	}

	var json_body: String = JSON.stringify(body_dict)

	print("================ 请求每日推送 ================")
	print("url: ", url)
	print("UserID: ", user_id)
	print("AppConversationID: ", app_conversation_id)
	print("Query: ", daily_query)
	print("json_body: ", json_body)
	print("==========================================")

	var err: int = agent_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if err != OK:
		_show_error("每日推送请求发送失败，错误码：" + str(err))


func _on_agent_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	var body_text: String = body.get_string_from_utf8()

	print("================ 每日推送返回 ================")
	print("step: ", current_step)
	print("result: ", result)
	print("response_code: ", response_code)
	print("body_text: ", body_text)
	print("==========================================")

	if result != HTTPRequest.RESULT_SUCCESS:
		_show_error("网络请求失败，请检查网络。")
		return

	if response_code != 200:
		_show_error("接口错误：" + str(response_code) + "\n\n返回内容：\n" + body_text)
		return

	var json := JSON.new()
	var parse_result: int = json.parse(body_text)

	if parse_result != OK:
		_show_error("返回内容不是合法 JSON：\n" + body_text)
		return

	var data = json.data

	match current_step:
		RequestStep.CREATE_CONVERSATION:
			_handle_create_conversation_response(data)

		RequestStep.DAILY_PUSH:
			_handle_daily_push_response(data)

		_:
			_show_error("未知请求状态")


func _handle_create_conversation_response(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		_show_error("创建会话返回格式异常")
		return

	if not data.has("Conversation"):
		_show_error("创建会话失败：缺少 Conversation 字段")
		return

	var conversation = data["Conversation"]

	if typeof(conversation) != TYPE_DICTIONARY:
		_show_error("创建会话失败：Conversation 格式异常")
		return

	if not conversation.has("AppConversationID"):
		_show_error("创建会话失败：缺少 AppConversationID")
		return

	app_conversation_id = str(conversation["AppConversationID"])

	print("每日推送会话创建成功，AppConversationID: ", app_conversation_id)

	_send_daily_push()


func _handle_daily_push_response(data) -> void:
	var answer: String = _extract_answer(data)

	if answer == "":
		_show_error("这次智能体返回为空，建议再点一次试试。")
		print("完整返回 data: ", data)
		return

	_display_daily_push(answer)


func _extract_answer(data) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return ""

	if data.has("answer"):
		var raw_answer = data["answer"]

		if typeof(raw_answer) == TYPE_DICTIONARY:
			if raw_answer.is_empty():
				return ""
			return JSON.stringify(raw_answer)

		if typeof(raw_answer) == TYPE_ARRAY:
			if raw_answer.is_empty():
				return ""
			return JSON.stringify(raw_answer)

		var answer: String = str(raw_answer).strip_edges()

		if answer == "{}" or answer == "[]" or answer == "null":
			return ""

		return answer

	if data.has("Data"):
		var data_str: String = str(data["Data"])
		var json := JSON.new()
		var parse_result: int = json.parse(data_str)

		if parse_result == OK:
			var inner = json.data
			if typeof(inner) == TYPE_DICTIONARY:
				return _extract_answer(inner)

	return ""


func _display_daily_push(answer: String) -> void:
	var image_url: String = _extract_first_image_url(answer)
	var clean_text: String = _remove_image_part(answer)

	var cat_today_text: String = _extract_section(clean_text, "校猫今日")
	var luck_advice_text: String = _extract_section(clean_text, "今日运势建议")

	if cat_today_text == "":
		cat_today_text = clean_text

	if luck_advice_text == "":
		luck_advice_text = "像猫猫一样，慢慢来，也是在认真生活喵。"

	cat_today_label.text = (
		"[font_size=22][b]🐾 校猫今日[/b][/font_size]\n\n"
		+ "[font_size=18][color=#F2F2F2]"
		+ cat_today_text
		+ "[/color][/font_size]"
	)

	luck_advice_label.text = (
		"[font_size=22][b]🔮 今日运势建议[/b][/font_size]\n\n"
		+ "[font_size=18][color=#F2F2F2]"
		+ luck_advice_text
		+ "[/color][/font_size]"
	)

	_finish_loading_ui()

	if image_url != "":
		status_label.text = "正在加载今日猫猫图片..."
		_load_cat_image(image_url)
	else:
		status_label.text = "今日推送已更新，但没有找到图片链接"


func _load_cat_image(url: String) -> void:
	pending_image_url = url

	var err: int = image_request.request(url)

	if err != OK:
		status_label.text = "图片加载失败，错误码：" + str(err)


func _on_image_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		status_label.text = "图片下载失败"
		return

	if response_code != 200:
		status_label.text = "图片接口错误：" + str(response_code)
		return

	var image := Image.new()
	var lower_url := pending_image_url.to_lower()

	var err: int = ERR_FILE_UNRECOGNIZED

	if lower_url.ends_with(".png"):
		err = image.load_png_from_buffer(body)
	elif lower_url.ends_with(".jpg") or lower_url.ends_with(".jpeg"):
		err = image.load_jpg_from_buffer(body)
	elif lower_url.ends_with(".webp"):
		err = image.load_webp_from_buffer(body)
	else:
		err = image.load_jpg_from_buffer(body)
		if err != OK:
			err = image.load_png_from_buffer(body)
		if err != OK:
			err = image.load_webp_from_buffer(body)

	if err != OK:
		status_label.text = "图片格式解析失败"
		return

	var texture := ImageTexture.create_from_image(image)
	cat_image.texture = texture

	status_label.text = "今日推送已更新"


func _extract_first_image_url(text: String) -> String:
	var lines: PackedStringArray = text.split("\n")

	for line in lines:
		var clean_line: String = line.strip_edges()
		var lower_line := clean_line.to_lower()

		if clean_line.begins_with("http://") or clean_line.begins_with("https://"):
			if lower_line.ends_with(".jpg") \
			or lower_line.ends_with(".jpeg") \
			or lower_line.ends_with(".png") \
			or lower_line.ends_with(".webp"):
				return clean_line

	return ""


func _remove_image_part(text: String) -> String:
	var lines: PackedStringArray = text.split("\n")
	var result_lines: Array[String] = []

	for line in lines:
		var clean_line: String = line.strip_edges()
		var lower_line := clean_line.to_lower()

		if clean_line.begins_with("!["):
			continue

		if clean_line.begins_with("http://") or clean_line.begins_with("https://"):
			if lower_line.ends_with(".jpg") \
			or lower_line.ends_with(".jpeg") \
			or lower_line.ends_with(".png") \
			or lower_line.ends_with(".webp"):
				continue

		result_lines.append(line)

	return "\n".join(result_lines).strip_edges()


func _extract_section(text: String, section_name: String) -> String:
	var marker_pos: int = text.find(section_name)

	if marker_pos == -1:
		return ""

	var after_marker: String = text.substr(marker_pos)

	var colon_pos: int = after_marker.find("：")
	if colon_pos == -1:
		colon_pos = after_marker.find(":")

	if colon_pos != -1:
		after_marker = after_marker.substr(colon_pos + 1)

	var next_section_pos: int = -1

	if section_name != "校猫今日":
		var p1: int = after_marker.find("校猫今日")
		if p1 != -1:
			next_section_pos = p1

	if section_name != "今日运势建议":
		var p2: int = after_marker.find("今日运势建议")
		if p2 != -1:
			if next_section_pos == -1 or p2 < next_section_pos:
				next_section_pos = p2

	if next_section_pos != -1:
		after_marker = after_marker.substr(0, next_section_pos)

	return _clean_markdown(after_marker.strip_edges())


func _clean_markdown(text: String) -> String:
	var result: String = text

	result = result.replace("**", "")
	result = result.replace("###", "")
	result = result.replace("##", "")
	result = result.replace("#", "")

	return result.strip_edges()


func _start_loading_ui() -> void:
	waiting_response = true
	push_button.disabled = true

	status_label.text = "正在获取今日推送..."

	cat_today_label.text = "[center][i]校猫正在观察今日状态...[/i][/center]"
	luck_advice_label.text = "[center][i]正在生成今日建议...[/i][/center]"


func _finish_loading_ui() -> void:
	waiting_response = false
	push_button.disabled = false
	current_step = RequestStep.NONE


func _show_error(msg: String) -> void:
	waiting_response = false
	push_button.disabled = false
	current_step = RequestStep.NONE

	status_label.text = "获取失败"

	cat_today_label.text = (
		"[font_size=22][b]获取失败[/b][/font_size]\n\n"
		+ "[font_size=18][color=#F2F2F2]"
		+ msg
		+ "[/color][/font_size]"
	)

	luck_advice_label.text = (
		"[font_size=18][color=#F2F2F2]"
		+ "可以稍后再试一次喵。"
		+ "[/color][/font_size]"
	)

	print("DailyPush Error: ", msg)


func _join_url(base_url: String, path: String) -> String:
	var clean_base: String = base_url.strip_edges()

	if clean_base.ends_with("/"):
		return clean_base + path

	return clean_base + "/" + path


func _on_to_map_pressed() -> void:
	var next_scene := "res://Scenes/map.tscn"
	SceneMemory.set_last_scene(next_scene)
	PawTransition.transition_to_scene(next_scene)
