extends Control

@export_file("*.tscn") var default_scene_path: String = "res://Scenes/start_scene.tscn"

@onready var username_input: LineEdit = $Panel/UsernameInput
@onready var password_input: LineEdit = $Panel/PasswordInput
@onready var remember_check_box: CheckBox = $Panel/RememberCheckBox
@onready var login_button: Button = $Panel/LoginButton
@onready var register_button: Button = $Panel/RegisterButton
@onready var message_label: Label = $Panel/MessageLabel

var is_navigating: bool = false

func _ready() -> void:
	password_input.secret = true
	message_label.text = ""

	login_button.pressed.connect(_on_login_button_pressed)
	register_button.pressed.connect(_on_register_button_pressed)

func _on_login_button_pressed() -> void:
	if is_navigating:
		return

	var username = username_input.text
	var password = password_input.text
	var remember = remember_check_box.button_pressed

	var result = AccountManager.login_user(username, password, remember)
	message_label.text = result["msg"]

	if result["success"]:
		is_navigating = true
		login_button.disabled = true
		register_button.disabled = true
		await get_tree().create_timer(0.3).timeout
		_go_after_login()

func _on_register_button_pressed() -> void:
	if is_navigating:
		return

	var username = username_input.text
	var password = password_input.text

	var register_result = AccountManager.register_user(username, password)
	message_label.text = register_result["msg"]

	if register_result["success"]:
		var remember = remember_check_box.button_pressed
		var login_result = AccountManager.login_user(username, password, remember)

		if login_result["success"]:
			message_label.text = "注册并登录成功"
			is_navigating = true
			login_button.disabled = true
			register_button.disabled = true
			await get_tree().create_timer(0.3).timeout
			_go_after_login()

func _go_after_login() -> void:
	var target_scene := default_scene_path

	if SceneMemory.has_last_scene():
		var saved_scene := SceneMemory.get_last_scene()
		if ResourceLoader.exists(saved_scene):
			target_scene = saved_scene

	get_tree().change_scene_to_file(target_scene)
