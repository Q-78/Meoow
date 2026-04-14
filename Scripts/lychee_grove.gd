extends Control

@onready var name_label: Label = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/NameLabel
@onready var message_label: RichTextLabel = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/Scroll/MessageLabel
@onready var user_input: LineEdit = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/InputRow/UserInput
@onready var send_button: Button = $UI/SafeArea/MainVBox/ChatPanel/ChatVBox/InputRow/SendButton
@onready var http_request: HTTPRequest = $HTTPRequest

@export var character_name: String = "芝麻糊"
@export var api_url: String = "https://api.dify.ai/v1/chat-messages"
@export var api_key: String = "YOUR_API_KEY"
@export var user_id: String = "godot_user_001"

var waiting_response: bool = false

func _ready() -> void:
	name_label.text = character_name
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.text = "你怎么才回来呀！今天过得怎么样？"
	
	send_button.pressed.connect(_on_send_pressed)
	user_input.text_submitted.connect(_on_input_submitted)
	http_request.request_completed.connect(_on_request_completed)

func _on_send_pressed() -> void:
	send_message()

func _on_input_submitted(_text: String) -> void:
	send_message()

func send_message() -> void:
	if waiting_response:
		return
	
	var text := user_input.text.strip_edges()
	if text == "":
		return
	
	waiting_response = true
	send_button.disabled = true
	user_input.editable = false
	
	message_label.text = "[b]你：[/b]" + text + "\n\n[i]正在思考...[/i]"
	user_input.clear()
	
	var headers = [
		"Authorization: Bearer " + api_key,
		"Content-Type: application/json"
	]
	
	var body_dict = {
		"inputs": {},
		"query": text,
		"response_mode": "blocking",
		"user": user_id
	}
	
	var json_body = JSON.stringify(body_dict)
	var err = http_request.request(api_url, headers, HTTPClient.METHOD_POST, json_body)
	
	if err != OK:
		waiting_response = false
		send_button.disabled = false
		user_input.editable = true
		message_label.text = "[b]你：[/b]" + text + "\n\n[b]" + character_name + "：[/b]请求发送失败"

func _on_request_completed(result, response_code, headers, body) -> void:
	waiting_response = false
	send_button.disabled = false
	user_input.editable = true
	
	var body_text = body.get_string_from_utf8()
	
	if response_code != 200:
		message_label.text += "\n\n[b]" + character_name + "：[/b]接口错误（" + str(response_code) + "）"
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body_text)
	if parse_result != OK:
		message_label.text += "\n\n[b]" + character_name + "：[/b]返回解析失败"
		return
	
	var data = json.data
	
	# Dify 常见 blocking 返回里通常有 answer 字段
	var answer = ""
	if typeof(data) == TYPE_DICTIONARY and data.has("answer"):
		answer = str(data["answer"])
	else:
		answer = "我刚刚发了一会儿呆，你再问我一次吧。"
	
	# 这里为了简洁，只保留当前这一轮
	var old_text = message_label.text
	var split_pos = old_text.find("\n\n[i]正在思考...[/i]")
	if split_pos != -1:
		old_text = old_text.substr(0, split_pos)
	
	message_label.text = old_text + "\n\n[b]" + character_name + "：[/b]" + answer


func _on_to_map_pressed() -> void:
	var next_scene := "res://Scenes/map.tscn"
	GameManager.clear_square_butterfly_state()
	PawTransition.transition_to_scene(next_scene)
