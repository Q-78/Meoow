extends Node

const ACCOUNTS_PATH := "user://accounts.json"
const SESSION_PATH := "user://session.json"

var accounts: Dictionary = {}
var current_user: String = ""
var remember_login: bool = false


func _ready() -> void:
	load_accounts()
	load_session()


# =========================
# 账号数据
# =========================
func load_accounts() -> void:
	if not FileAccess.file_exists(ACCOUNTS_PATH):
		accounts = {}
		save_accounts()
		return

	var file = FileAccess.open(ACCOUNTS_PATH, FileAccess.READ)
	if file == null:
		accounts = {}
		return

	var content = file.get_as_text()
	file.close()

	if content.strip_edges() == "":
		accounts = {}
		return

	var result = JSON.parse_string(content)
	if typeof(result) == TYPE_DICTIONARY:
		accounts = result
	else:
		accounts = {}


func save_accounts() -> void:
	var file = FileAccess.open(ACCOUNTS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法保存 accounts.json")
		return

	file.store_string(JSON.stringify(accounts))
	file.close()


func hash_password(password: String) -> String:
	return password.sha256_text()


# =========================
# 会话数据（记住登录）
# =========================
func load_session() -> void:
	current_user = ""
	remember_login = false

	if not FileAccess.file_exists(SESSION_PATH):
		save_session()
		return

	var file = FileAccess.open(SESSION_PATH, FileAccess.READ)
	if file == null:
		return

	var content = file.get_as_text()
	file.close()

	if content.strip_edges() == "":
		return

	var result = JSON.parse_string(content)
	if typeof(result) != TYPE_DICTIONARY:
		return

	var saved_user = str(result.get("current_user", ""))
	var saved_remember = bool(result.get("remember_login", false))

	# 只有勾选“记住登录”，且用户确实存在，才恢复登录
	if saved_remember and saved_user != "" and accounts.has(saved_user):
		current_user = saved_user
		remember_login = true


func save_session() -> void:
	var file = FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法保存 session.json")
		return

	var session_data = {
		"current_user": current_user,
		"remember_login": remember_login
	}

	file.store_string(JSON.stringify(session_data))
	file.close()


func clear_session() -> void:
	current_user = ""
	remember_login = false
	save_session()


# =========================
# 注册 / 登录 / 退出
# =========================
func register_user(username: String, password: String) -> Dictionary:
	username = username.strip_edges()
	password = password.strip_edges()

	if username == "" or password == "":
		return {
			"success": false,
			"msg": "用户名和密码不能为空"
		}

	if username.length() < 3:
		return {
			"success": false,
			"msg": "用户名至少需要3位"
		}

	if password.length() < 6:
		return {
			"success": false,
			"msg": "密码至少需要6位"
		}

	if accounts.has(username):
		return {
			"success": false,
			"msg": "用户名已存在"
		}

	accounts[username] = {
		"password": hash_password(password),
		"created_at": Time.get_datetime_string_from_system(),
		"player_data": {
			"intimacy": 0,
			"coins": 0
		}
	}

	save_accounts()

	return {
		"success": true,
		"msg": "注册成功"
	}


func login_user(username: String, password: String, remember: bool) -> Dictionary:
	username = username.strip_edges()
	password = password.strip_edges()

	if username == "" or password == "":
		return {
			"success": false,
			"msg": "用户名和密码不能为空"
		}

	if not accounts.has(username):
		return {
			"success": false,
			"msg": "用户不存在"
		}

	var user_info = accounts[username]
	var saved_hash = str(user_info.get("password", ""))

	if saved_hash != hash_password(password):
		return {
			"success": false,
			"msg": "密码错误"
		}

	current_user = username
	remember_login = remember
	save_session()

	return {
		"success": true,
		"msg": "登录成功"
	}


func logout() -> void:
	clear_session()


func is_logged_in() -> bool:
	return current_user != ""


# =========================
# 当前用户数据读写
# =========================
func get_current_user_data() -> Dictionary:
	if current_user == "":
		return {}

	if not accounts.has(current_user):
		return {}

	return accounts[current_user]


func get_current_player_data() -> Dictionary:
	if current_user == "":
		return {}

	if not accounts.has(current_user):
		return {}

	var user_info = accounts[current_user]
	return user_info.get("player_data", {})


func update_current_player_data(new_data: Dictionary) -> void:
	if current_user == "":
		return

	if not accounts.has(current_user):
		return

	var user_info = accounts[current_user]
	user_info["player_data"] = new_data
	accounts[current_user] = user_info
	save_accounts()


func get_current_username() -> String:
	return current_user
