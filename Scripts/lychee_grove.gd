extends Control

@onready var name_label: Label = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/NameLabel
@onready var message_label: RichTextLabel = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/Scroll/MessageLabel
@onready var user_input: LineEdit = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/InputRow/UserInput
@onready var send_button: Button = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/InputRow/SendButton
@onready var http_request: HTTPRequest = $HTTPRequest

# ==============================
# 【新增】使用说明面板相关节点
# ==============================
@onready var help_button: Button = $UI/HelpButton
@onready var help_panel: Panel = $UI/HelpPanel
@onready var help_text: RichTextLabel = $UI/HelpPanel/HelpText
@onready var close_button: Button = $UI/HelpPanel/CloseButton
# ==============================

@export var character_name: String = "芝麻糊"

# 【修改】HiAgent API 基础地址
@export var api_base_url: String = "https://agent.hit.edu.cn/api/proxy/api/v1"

# 【修改】填你 PowerShell 测试成功的 API Key
@export var api_key: String = "d862c55g77ds2k2dggs0"

# 【修改】UserID 文档要求 1-20 位，godot_user_001 可以用
@export var user_id: String = "godot_user_001"

var waiting_response: bool = false

# 【新增】保存当前会话 ID
var app_conversation_id: String = ""

# 【新增】保存用户刚刚输入的话
var pending_user_text: String = ""

# ==============================
# 【新增】使用说明内容
# ==============================
const HELP_CONTENT := """
[center][font_size=16][b][color=#6A4A40]🐱 欢迎来到 Meoow_校猫平台！[/color][/b][/font_size][/center]
[color=#7A5A4B]这里有三只性格各异的小猫咪等你认领：[/color]
[center][b][color=#8B5E4B]「芝麻糊」  「奥利奥」  「杏仁糖」[/color][/b][/center]
[color=#7A5A4B]每只都有专属小脾气～[/color]
[b][color=#C27A4A]✨ 猫猫们的专属服务清单：[/color][/b]
[b][color=#6A4A40]1. 树洞闲聊[/color][/b]
[color=#7A5A4B]像和小猫加了 WeChat，选择你喜欢的小猫开始聊天。[/color]

[b][color=#6A4A40]2. 奥利奥限定・哲学唠嗑局[/color][/b]
[color=#7A5A4B]想聊人生困惑、探讨思考？奥利奥是猫群里的“思想小哲学家”。[/color]

[b][color=#6A4A40]3. 沉浸式趣味心理测试[/color][/b]
[color=#7A5A4B]恋爱 / 职业 / 性格倾向等多种类型都能测。输入 [b]test_type[/b]或者xx测试即可开启。
测试轮数固定为 [b]6[/b]，初始选择 [b]0[/b] 就好。
跟着小猫引导表达，结果会更贴合真实的你。[/color]

[b][color=#6A4A40]4. 每日猫猫惊喜推送[/color][/b]
[color=#7A5A4B]每天早上 9 点自动掉落治愈小猫图文。
也可以直接说：[b]「今日小猫推送」[/b]、[b]「爱猫猫」[/b]、[b]「想猫猫」[/b]。[/color]

"""
# ==============================

enum RequestStep {
	NONE,
	CREATE_CONVERSATION,
	CHAT_QUERY
}

var current_step: RequestStep = RequestStep.NONE


func _ready() -> void:
	name_label.text = character_name
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.text = "你怎么才回来呀！今天过得怎么样？"
	
	send_button.pressed.connect(_on_send_pressed)
	user_input.text_submitted.connect(_on_input_submitted)
	http_request.request_completed.connect(_on_request_completed)
	
	help_panel.visible = false

	# 【新增】美化说明面板
	_setup_help_panel_style()
	_setup_help_text_style()
	_setup_close_button_style()

	help_text.text = HELP_CONTENT

	help_button.pressed.connect(_on_help_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

func _setup_help_panel_style() -> void:
	var panel_style := StyleBoxFlat.new()
	
	# 【修改】不要用灰色透明，改成温暖的奶油白
	panel_style.bg_color = Color("#FFF7EBDD")
	
	# 【修改】柔和圆角
	panel_style.corner_radius_top_left = 22
	panel_style.corner_radius_top_right = 22
	panel_style.corner_radius_bottom_left = 22
	panel_style.corner_radius_bottom_right = 22
	
	# 【新增】内边距，让文字不要贴边
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 18
	panel_style.content_margin_bottom = 18
	
	# 【新增】浅棕色描边，让卡片从背景里浮出来
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color("#E5C9A8AA")
	
	# 【新增】柔和阴影
	panel_style.shadow_color = Color("#5A403022")
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 4)
	
	help_panel.add_theme_stylebox_override("panel", panel_style)


func _setup_help_text_style() -> void:
	help_text.bbcode_enabled = true
	help_text.scroll_active = true
	help_text.fit_content = false
	
	# 【修改】字号保持清晰，不要太小
	help_text.add_theme_font_size_override("normal_font_size", 15)
	help_text.add_theme_font_size_override("bold_font_size", 15)
	help_text.add_theme_font_size_override("italics_font_size", 15)
	help_text.add_theme_font_size_override("bold_italics_font_size", 15)
	
	# 【修改】深棕色文字，比白字更适合浅色卡片
	help_text.add_theme_color_override("default_color", Color("#5B4035"))
	
	# 【修改】不要描边，避免文字变糊
	help_text.add_theme_constant_override("outline_size", 0)
	
	# 【新增】行距
	help_text.add_theme_constant_override("line_separation", 0)
	
	# 【新增】滚动条变细
	await get_tree().process_frame
	
	var v_scroll_bar := help_text.get_v_scroll_bar()
	if v_scroll_bar:
		v_scroll_bar.custom_minimum_size.x = 4
		
		var scroll_bg := StyleBoxFlat.new()
		scroll_bg.bg_color = Color(0, 0, 0, 0)
		v_scroll_bar.add_theme_stylebox_override("scroll", scroll_bg)
		
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color("#B9957BAA")
		grabber.corner_radius_top_left = 2
		grabber.corner_radius_top_right = 2
		grabber.corner_radius_bottom_left = 2
		grabber.corner_radius_bottom_right = 2
		
		v_scroll_bar.add_theme_stylebox_override("grabber", grabber)
		v_scroll_bar.add_theme_stylebox_override("grabber_highlight", grabber)
		v_scroll_bar.add_theme_stylebox_override("grabber_pressed", grabber)


func _setup_close_button_style() -> void:
	close_button.text = "×"
	
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("#F8E8D6EE")
	normal_style.corner_radius_top_left = 14
	normal_style.corner_radius_top_right = 14
	normal_style.corner_radius_bottom_left = 14
	normal_style.corner_radius_bottom_right = 14
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color("#C9A98AAA")
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color("#FFE8DDEE")
	hover_style.corner_radius_top_left = 14
	hover_style.corner_radius_top_right = 14
	hover_style.corner_radius_bottom_left = 14
	hover_style.corner_radius_bottom_right = 14
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color("#C78C7AAA")
	
	close_button.add_theme_stylebox_override("normal", normal_style)
	close_button.add_theme_stylebox_override("hover", hover_style)
	close_button.add_theme_stylebox_override("pressed", hover_style)
	close_button.add_theme_color_override("font_color", Color("#6A4A40"))
	close_button.add_theme_font_size_override("font_size", 20)
# ==============================
# 【新增】点击 ? 按钮，显示说明面板
# ==============================
func _on_help_button_pressed() -> void:
	help_panel.visible = true


# ==============================
# 【新增】点击关闭按钮，隐藏说明面板
# ==============================
func _on_close_button_pressed() -> void:
	help_panel.visible = false


func _on_send_pressed() -> void:
	send_message()


func _on_input_submitted(_text: String) -> void:
	send_message()


func send_message() -> void:
	if waiting_response:
		return
	
	var text: String = user_input.text.strip_edges()
	if text == "":
		return
	
	pending_user_text = text
	
	waiting_response = true
	send_button.disabled = true
	user_input.editable = false
	
	message_label.text = "[b]你：[/b]" + text + "\n\n[i]正在思考...[/i]"
	user_input.clear()
	
	# 第一次对话前，先创建会话
	if app_conversation_id == "":
		_create_conversation()
	else:
		_chat_query_v2(text)


# ==============================
# 【新增】创建会话
# ==============================
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
	
	print("================ 创建会话 ================")
	print("url: ", url)
	print("UserID: ", user_id)
	print("json_body: ", json_body)
	print("========================================")
	
	var err: int = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if err != OK:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]创建会话请求发送失败，错误码：" + str(err)


# ==============================
# 【新增】发送聊天请求 V2
# ==============================
func _chat_query_v2(text: String) -> void:
	current_step = RequestStep.CHAT_QUERY
	
	var url: String = _join_url(api_base_url, "chat_query_v2")
	
	var headers: Array[String] = [
		"Apikey: " + api_key,
		"Content-Type: application/json"
	]
	
	var body_dict = {
		"UserID": user_id,
		"AppConversationID": app_conversation_id,
		"Query": text,
		"ResponseMode": "blocking"
	}
	
	var json_body: String = JSON.stringify(body_dict)
	
	print("================ 发送消息 ================")
	print("url: ", url)
	print("UserID: ", user_id)
	print("AppConversationID: ", app_conversation_id)
	print("Query: ", text)
	print("json_body: ", json_body)
	print("========================================")
	
	var err: int = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)
	
	if err != OK:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]聊天请求发送失败，错误码：" + str(err)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_text: String = body.get_string_from_utf8()
	
	print("================ 返回结果 ================")
	print("step: ", current_step)
	print("result: ", result)
	print("response_code: ", response_code)
	print("body_text: ", body_text)
	print("========================================")
	
	if result != HTTPRequest.RESULT_SUCCESS:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]网络请求失败，请检查网络。"
		return
	
	if response_code != 200:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]接口错误（" + str(response_code) + "）"
		message_label.text += "\n\n返回内容：\n" + body_text
		return
	
	var json := JSON.new()
	var parse_result: int = json.parse(body_text)
	
	if parse_result != OK:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]返回解析失败"
		message_label.text += "\n\n原始返回：\n" + body_text
		return
	
	var data = json.data
	
	match current_step:
		RequestStep.CREATE_CONVERSATION:
			_handle_create_conversation_response(data)
		
		RequestStep.CHAT_QUERY:
			_handle_chat_query_response(data)
		
		_:
			_reset_input_state()
			message_label.text += "\n\n[b]" + character_name + "：[/b]未知请求状态"


# ==============================
# 【新增】处理 create_conversation 返回
# ==============================
func _handle_create_conversation_response(data) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]创建会话返回格式异常"
		return
	
	if not data.has("Conversation"):
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]创建会话失败：缺少 Conversation 字段"
		print("create_conversation data: ", data)
		return
	
	var conversation = data["Conversation"]
	
	if typeof(conversation) != TYPE_DICTIONARY:
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]创建会话失败：Conversation 格式异常"
		return
	
	if not conversation.has("AppConversationID"):
		_reset_input_state()
		message_label.text += "\n\n[b]" + character_name + "：[/b]创建会话失败：缺少 AppConversationID"
		print("conversation data: ", conversation)
		return
	
	app_conversation_id = str(conversation["AppConversationID"])
	
	print("创建会话成功，AppConversationID: ", app_conversation_id)
	
	# 创建会话成功后，继续发送刚才用户输入的问题
	_chat_query_v2(pending_user_text)


# ==============================
# 【新增】处理 chat_query_v2 返回
# ==============================
func _handle_chat_query_response(data) -> void:
	_reset_input_state()
	
	var answer: String = _extract_answer(data)
	
	if answer == "":
		answer = "喵……我刚刚走神了一下，你再和我说一遍好不好？"
		print("本次回答为空或无效，完整返回 data: ", data)
	
	var old_text: String = message_label.text
	var split_pos: int = old_text.find("\n\n[i]正在思考...[/i]")
	
	if split_pos != -1:
		old_text = old_text.substr(0, split_pos)
	
	message_label.text = old_text + "\n\n[b]" + character_name + "：[/b]" + answer


# ==============================
# 【新增】提取 answer
# ==============================
func _extract_answer(data) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	
	if data.has("answer"):
		var raw_answer = data["answer"]
		
		# 【新增】如果 answer 是字典，而且是空字典，说明不是正常文本
		if typeof(raw_answer) == TYPE_DICTIONARY:
			if raw_answer.is_empty():
				return ""
			return JSON.stringify(raw_answer)
		
		# 【新增】如果 answer 是数组，也不要直接显示
		if typeof(raw_answer) == TYPE_ARRAY:
			if raw_answer.is_empty():
				return ""
			return JSON.stringify(raw_answer)
		
		var answer: String = str(raw_answer).strip_edges()
		
		# 【新增】过滤无意义回答
		if answer == "{}" or answer == "[]" or answer == "null":
			return ""
		
		return answer
	
	if data.has("Data"):
		var data_str: String = str(data["Data"])
		var json := JSON.new()
		var parse_result: int = json.parse(data_str)
		
		if parse_result == OK:
			var inner = json.data
			if typeof(inner) == TYPE_DICTIONARY and inner.has("answer"):
				return _extract_answer(inner)
	
	return ""


func _reset_input_state() -> void:
	waiting_response = false
	send_button.disabled = false
	user_input.editable = true
	current_step = RequestStep.NONE


func _join_url(base_url: String, path: String) -> String:
	var clean_base: String = base_url.strip_edges()
	
	if clean_base.ends_with("/"):
		return clean_base + path
	
	return clean_base + "/" + path


func _on_to_map_pressed() -> void:
	var next_scene := "res://Scenes/map.tscn"
	GameManager.clear_square_butterfly_state()
	PawTransition.transition_to_scene(next_scene)
