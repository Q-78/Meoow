##extends Node2D
##
### =========================
### 节点引用
### =========================
##@onready var http: HTTPRequest = $HTTPRequest
##
##@onready var chat_history: RichTextLabel = $DialogUI/Panel/ChatHistory
##@onready var input_box: LineEdit = $DialogUI/Panel/InputBox
##@onready var send_button: Button = $DialogUI/Panel/SendButton
##@onready var clear_button: Button = $DialogUI/Panel/ClearButton
##@onready var status_label: Label = $DialogUI/Panel/StatusLabel
##
##
### =========================
### 配置区
### =========================
##
### 调试模式：
### true  = 用免费测试接口（你给的 chucknorris）
### false = 用你自己的大模型接口
##@export var use_test_api: bool = false
##
### 你自己的模型接口配置（后面替换）
##@export var api_url: String = "https://api.dify.ai/v1"
##
##@export var api_key: String = "YOUR_API_KEY"
##@export var model_name: String = "YOUR_MODEL_NAME"
##
### 是否正在请求中，防止连续点击
##var is_waiting: bool = false
##
### 简单保存聊天上下文
##var messages: Array = []
##
##
##func _ready() -> void:
	##http.request_completed.connect(_on_request_completed)
##
	##send_button.pressed.connect(_on_send_button_pressed)
	##clear_button.pressed.connect(_on_clear_button_pressed)
	##input_box.text_submitted.connect(_on_input_submitted)
##
	##status_label.text = ""
	##_append_system_message("欢迎来到树洞。你可以把想说的话告诉我。")
##
##
### =========================
### UI 事件
### =========================
##func _on_send_button_pressed() -> void:
	##_send_current_text()
##
##
##func _on_input_submitted(_new_text: String) -> void:
	##_send_current_text()
##
##
##func _on_clear_button_pressed() -> void:
	##chat_history.clear()
	##messages.clear()
	##status_label.text = ""
	##_append_system_message("聊天记录已清空。")
##
##
### =========================
### 发送逻辑
### =========================
##func _send_current_text() -> void:
	##if is_waiting:
		##return
##
	##var user_text := input_box.text.strip_edges()
	##if user_text == "":
		##return
##
	##input_box.clear()
	##_append_user_message(user_text)
##
	### 记录上下文
	##messages.append({
		##"role": "user",
		##"content": user_text
	##})
##
	##is_waiting = true
	##send_button.disabled = true
	##status_label.text = "正在思考..."
##
	##if use_test_api:
		##_request_test_api()
	##else:
		##_request_model_api()
##
##
### =========================
### 测试接口（GET）
### 先验证 HTTPRequest 是否正常工作
### =========================
##func _request_test_api() -> void:
	##var url = "https://api.chucknorris.io/jokes/random"
	##var err = http.request(url)
##
	##if err != OK:
		##_on_request_failed("测试请求发送失败，错误码: %s" % err)
##
##
### =========================
### 大模型接口（POST）
### 这里是通用写法，你后面按自己的 API 格式调整
### =========================
##func _request_model_api() -> void:
	##var headers = [
		##"Content-Type: application/json",
		##"Authorization: Bearer %s" % api_key
	##]
##
	##var body_dict = {
		##"model": model_name,
		##"messages": messages,
		##"temperature": 0.7
	##}
##
	##var body_json = JSON.stringify(body_dict)
##
	##var err = http.request(
		##api_url,
		##headers,
		##HTTPClient.METHOD_POST,
		##body_json
	##)
##
	##if err != OK:
		##_on_request_failed("模型请求发送失败，错误码: %s" % err)
##
##
### =========================
### 请求回调
### =========================
##func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	##is_waiting = false
	##send_button.disabled = false
##
	##var text := body.get_string_from_utf8()
	##print("请求结果 result =", result)
	##print("状态码 response_code =", response_code)
	##print("返回数据 =", text)
##
	##if result != HTTPRequest.RESULT_SUCCESS:
		##_on_request_failed("网络请求失败，result = %s" % result)
		##return
##
	##if response_code < 200 or response_code >= 300:
		##_on_request_failed("接口返回错误，状态码: %s" % response_code)
		##return
##
	##var json = JSON.parse_string(text)
	##if json == null:
		##_on_request_failed("返回数据不是合法 JSON")
		##return
##
	##var reply_text := ""
##
	##if use_test_api:
		### 适配 chucknorris 测试接口
		##if json.has("value"):
			##reply_text = str(json["value"])
		##else:
			##reply_text = "测试接口没有返回 value 字段。"
	##else:
		### 这里按常见 chat/completions 格式解析
		### 如果你的接口格式不同，只改这里就行
		##if json.has("choices") and json["choices"].size() > 0:
			##var choice = json["choices"][0]
			##if choice.has("message") and choice["message"].has("content"):
				##reply_text = str(choice["message"]["content"])
			##else:
				##reply_text = "接口返回中没有 message.content 字段。"
		##else:
			##reply_text = "接口返回中没有 choices 字段。"
##
	##_append_ai_message(reply_text)
##
	### 加入上下文
	##messages.append({
		##"role": "assistant",
		##"content": reply_text
	##})
##
	##status_label.text = ""
##
##
##func _on_request_failed(msg: String) -> void:
	##is_waiting = false
	##send_button.disabled = false
	##status_label.text = msg
	##_append_system_message("[错误] " + msg)
	##print(msg)
##
##
### =========================
### 聊天显示
### =========================
##func _append_user_message(text: String) -> void:
	##chat_history.append_text("[color=#8fd3ff]你：[/color]%s\n\n" % text)
	##_scroll_chat_to_bottom()
##
##
##func _append_ai_message(text: String) -> void:
	##chat_history.append_text("[color=#a8ffb0]树洞：[/color]%s\n\n" % text)
	##_scroll_chat_to_bottom()
##
##
##func _append_system_message(text: String) -> void:
	##chat_history.append_text("[color=#cccccc]%s[/color]\n\n" % text)
	##_scroll_chat_to_bottom()
##
##
##func _scroll_chat_to_bottom() -> void:
	##await get_tree().process_frame
	##chat_history.scroll_to_line(chat_history.get_line_count())
#
#extends Node2D
#
#@onready var http: HTTPRequest = $HTTPRequest
#
#@onready var chat_history: RichTextLabel = $DialogUI/Panel/ChatHistory
#@onready var input_box: LineEdit = $DialogUI/Panel/InputBox
#@onready var send_button: Button = $DialogUI/Panel/SendButton
#@onready var clear_button: Button = $DialogUI/Panel/ClearButton
#@onready var status_label: Label = $DialogUI/Panel/StatusLabel
#
#@export var use_test_api: bool = false
#@export var api_url: String = "https://api.dify.ai/v1/chat-messages"
#@export var api_key: String = "app-o2W7o74J814kusdjkVnOQyo7"
#@export var dify_user_id: String = "godot_user_001"
#
#var is_waiting: bool = false
#var conversation_id: String = ""
#
#
#func _ready() -> void:
	#http.request_completed.connect(_on_request_completed)
#
	#send_button.pressed.connect(_on_send_button_pressed)
	#clear_button.pressed.connect(_on_clear_button_pressed)
	#input_box.text_submitted.connect(_on_input_submitted)
#
	#status_label.text = ""
	#_append_system_message("欢迎来到树洞。你可以把想说的话告诉我。")
#
#
#func _on_send_button_pressed() -> void:
	#_send_current_text()
#
#
#func _on_input_submitted(_new_text: String) -> void:
	#_send_current_text()
#
#
#func _on_clear_button_pressed() -> void:
	#chat_history.clear()
	#status_label.text = ""
	#conversation_id = ""
	#_append_system_message("聊天记录已清空。")
#
#
#func _send_current_text() -> void:
	#if is_waiting:
		#return
#
	#var user_text := input_box.text.strip_edges()
	#if user_text == "":
		#return
#
	#input_box.clear()
	#_append_user_message(user_text)
#
	#is_waiting = true
	#send_button.disabled = true
	#status_label.text = "正在思考..."
#
	#if use_test_api:
		#_request_test_api()
	#else:
		#_request_model_api(user_text)
#
#
#func _request_test_api() -> void:
	#var url = "https://api.chucknorris.io/jokes/random"
	#var err = http.request(url)
#
	#if err != OK:
		#_on_request_failed("测试请求发送失败，错误码: %s" % err)
#
#
#func _request_model_api(user_text: String) -> void:
	#var headers = [
		#"Content-Type: application/json",
		#"Authorization: Bearer %s" % api_key
	#]
#
	#var body_dict = {
		#"inputs": {},
		#"query": user_text,
		#"response_mode": "blocking",
		#"conversation_id": conversation_id,
		#"user": dify_user_id
	#}
#
	#var body_json = JSON.stringify(body_dict)
	#print("请求地址 =", api_url)
	#print("请求体 =", body_json)
#
	#var err = http.request(
		#api_url,
		#headers,
		#HTTPClient.METHOD_POST,
		#body_json
	#)
#
	#if err != OK:
		#_on_request_failed("模型请求发送失败，错误码: %s" % err)
#
#
#func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	#is_waiting = false
	#send_button.disabled = false
#
	#var text := body.get_string_from_utf8()
	#print("请求结果 result =", result)
	#print("状态码 response_code =", response_code)
	#print("返回数据 =", text)
#
	#if result != HTTPRequest.RESULT_SUCCESS:
		#_on_request_failed("网络请求失败，result = %s" % result)
		#return
#
	#if response_code < 200 or response_code >= 300:
		#_on_request_failed("接口返回错误，状态码: %s\n返回内容: %s" % [response_code, text])
		#return
#
	#var json = JSON.parse_string(text)
	#if json == null:
		#_on_request_failed("返回数据不是合法 JSON")
		#return
#
	#var reply_text := ""
#
	#if use_test_api:
		#if json.has("value"):
			#reply_text = str(json["value"])
		#else:
			#reply_text = "测试接口没有返回 value 字段。"
	#else:
		#if json.has("conversation_id"):
			#conversation_id = str(json["conversation_id"])
#
		#if json.has("answer"):
			#reply_text = str(json["answer"])
		#else:
			#reply_text = "接口返回中没有 answer 字段。"
#
	#_append_ai_message(reply_text)
	#status_label.text = ""
#
#
#func _on_request_failed(msg: String) -> void:
	#is_waiting = false
	#send_button.disabled = false
	#status_label.text = msg
	#_append_system_message("[错误] " + msg)
	#print(msg)
#
#
#func _append_user_message(text: String) -> void:
	#chat_history.append_text("[color=#8fd3ff]你：[/color]%s\n\n" % text)
	#_scroll_chat_to_bottom()
#
#
#func _append_ai_message(text: String) -> void:
	#chat_history.append_text("[color=#a8ffb0]树洞：[/color]%s\n\n" % text)
	#_scroll_chat_to_bottom()
#
#
#func _append_system_message(text: String) -> void:
	#chat_history.append_text("[color=#cccccc]%s[/color]\n\n" % text)
	#_scroll_chat_to_bottom()
#
#
#func _scroll_chat_to_bottom() -> void:
	#await get_tree().process_frame
	#chat_history.scroll_to_line(chat_history.get_line_count())
#
#
#func _on_to_map_pressed() -> void:
	#get_tree().change_scene_to_file("res://Scenes/map.tscn")


extends Node2D

enum ChatMode {
	NORMAL,
	PERSONALITY_TEST
}

@onready var http: HTTPRequest = $HTTPRequest

@onready var chat_history: RichTextLabel = $DialogUI/Panel/ChatHistory
@onready var input_box: LineEdit = $DialogUI/Panel/InputBox
@onready var send_button: Button = $DialogUI/Panel/SendButton
@onready var clear_button: Button = $DialogUI/Panel/ClearButton
@onready var status_label: Label = $DialogUI/Panel/StatusLabel

@export var use_test_api: bool = false
@export var api_url: String = "https://api.dify.ai/v1/chat-messages"

# 两种模式分别对应不同的 key
@export var api_key_normal: String = "你的普通模式key"
@export var api_key_test: String = "你的性格测试模式key"

@export var dify_user_id: String = "godot_user_001"

var current_mode: ChatMode = ChatMode.NORMAL
var is_waiting: bool = false
var conversation_id: String = ""


func _ready() -> void:
	http.request_completed.connect(_on_request_completed)

	send_button.pressed.connect(_on_send_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	input_box.text_submitted.connect(_on_input_submitted)

	status_label.text = ""
	_append_system_message("欢迎来到树洞。你可以把想说的话告诉我。")
	_append_system_message("输入 /chat 切换到普通模式")
	_append_system_message("输入 /test 切换到性格测试模式")


func _on_send_button_pressed() -> void:
	_send_current_text()


func _on_input_submitted(_new_text: String) -> void:
	_send_current_text()


func _on_clear_button_pressed() -> void:
	chat_history.clear()
	status_label.text = ""
	conversation_id = ""
	_append_system_message("聊天记录已清空。")


func _send_current_text() -> void:
	if is_waiting:
		return

	var user_text := input_box.text.strip_edges()
	if user_text == "":
		return

	input_box.clear()
	_append_user_message(user_text)

	# 切换到普通模式
	if user_text == "/chat":
		current_mode = ChatMode.NORMAL
		conversation_id = ""
		_append_system_message("已切换到【普通模式】")
		return

	# 切换到性格测试模式
	if user_text == "/test":
		current_mode = ChatMode.PERSONALITY_TEST
		conversation_id = ""
		_append_system_message("已切换到【性格测试模式】")
		return

	is_waiting = true
	send_button.disabled = true
	status_label.text = "正在思考..."

	if use_test_api:
		_request_test_api()
	else:
		_request_model_api(user_text)


func _request_test_api() -> void:
	var url = "https://api.chucknorris.io/jokes/random"
	var err = http.request(url)

	if err != OK:
		_on_request_failed("测试请求发送失败，错误码: %s" % err)


func _request_model_api(user_text: String) -> void:
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % _get_current_api_key()
	]

	var body_dict = {
		"inputs": {
			"mode": _get_mode_name()
		},
		"query": user_text,
		"response_mode": "blocking",
		"conversation_id": conversation_id,
		"user": dify_user_id
	}

	var body_json = JSON.stringify(body_dict)
	print("当前模式 =", _get_mode_name())
	print("请求地址 =", api_url)
	print("请求体 =", body_json)

	var err = http.request(
		api_url,
		headers,
		HTTPClient.METHOD_POST,
		body_json
	)

	if err != OK:
		_on_request_failed("模型请求发送失败，错误码: %s" % err)


func _get_current_api_key() -> String:
	match current_mode:
		ChatMode.NORMAL:
			return api_key_normal
		ChatMode.PERSONALITY_TEST:
			return api_key_test
	return api_key_normal


func _get_mode_name() -> String:
	match current_mode:
		ChatMode.NORMAL:
			return "normal"
		ChatMode.PERSONALITY_TEST:
			return "personality_test"
	return "normal"


func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	is_waiting = false
	send_button.disabled = false

	var text := body.get_string_from_utf8()
	print("请求结果 result =", result)
	print("状态码 response_code =", response_code)
	print("返回数据 =", text)

	if result != HTTPRequest.RESULT_SUCCESS:
		_on_request_failed("网络请求失败，result = %s" % result)
		return

	if response_code < 200 or response_code >= 300:
		_on_request_failed("接口返回错误，状态码: %s\n返回内容: %s" % [response_code, text])
		return

	var json = JSON.parse_string(text)
	if json == null:
		_on_request_failed("返回数据不是合法 JSON")
		return

	var reply_text := ""

	if use_test_api:
		if json.has("value"):
			reply_text = str(json["value"])
		else:
			reply_text = "测试接口没有返回 value 字段。"
	else:
		if json.has("conversation_id"):
			conversation_id = str(json["conversation_id"])

		if json.has("answer"):
			reply_text = str(json["answer"])
		else:
			reply_text = "接口返回中没有 answer 字段。"

	_append_ai_message(reply_text)
	status_label.text = ""


func _on_request_failed(msg: String) -> void:
	is_waiting = false
	send_button.disabled = false
	status_label.text = msg
	_append_system_message("[错误] " + msg)
	print(msg)


func _append_user_message(text: String) -> void:
	chat_history.append_text("[color=#8fd3ff]你：[/color]%s\n\n" % text)
	_scroll_chat_to_bottom()


func _append_ai_message(text: String) -> void:
	chat_history.append_text("[color=#a8ffb0]树洞：[/color]%s\n\n" % text)
	_scroll_chat_to_bottom()


func _append_system_message(text: String) -> void:
	chat_history.append_text("[color=#cccccc]%s[/color]\n\n" % text)
	_scroll_chat_to_bottom()


func _scroll_chat_to_bottom() -> void:
	await get_tree().process_frame
	chat_history.scroll_to_line(chat_history.get_line_count())


func _on_to_map_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
