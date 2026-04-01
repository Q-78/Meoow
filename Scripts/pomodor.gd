#extends Control
#
#@onready var time_label = $TimeLabel
#@onready var minute_input = $MinuteInput
#@onready var start_button = $StartButton
#@onready var pause_button = $PauseButton
#@onready var reset_button = $ResetButton
#@onready var status_label = $StatusLabel
#@onready var timer = $Timer
#
#var total_time: int = 25 * 60      # 总时间（秒）
#var remaining_time: int = 25 * 60  # 剩余时间（秒）
#var is_running: bool = false
#var is_paused: bool = false
#
#func _ready():
	#update_time_label()
	#status_label.text = "未开始"
	#
	#start_button.pressed.connect(_on_start_button_pressed)
	#pause_button.pressed.connect(_on_pause_button_pressed)
	#reset_button.pressed.connect(_on_reset_button_pressed)
	#timer.timeout.connect(_on_timer_timeout)
#
#func update_time_label():
	#var minutes = remaining_time / 60
	#var seconds = remaining_time % 60
	#time_label.text = "%02d:%02d" % [minutes, seconds]
#
#func _on_start_button_pressed():
	## 如果当前没有在运行，就从输入框读取时间
	#if not is_running:
		#total_time = int(minute_input.value) * 60
		#remaining_time = total_time
	#
	#timer.start()
	#is_running = true
	#is_paused = false
	#status_label.text = "进行中"
#
#func _on_pause_button_pressed():
	#if is_running and not is_paused:
		#timer.stop()
		#is_paused = true
		#status_label.text = "已暂停"
	#elif is_running and is_paused:
		#timer.start()
		#is_paused = false
		#status_label.text = "进行中"
#
#func _on_reset_button_pressed():
	#timer.stop()
	#is_running = false
	#is_paused = false
	#total_time = int(minute_input.value) * 60
	#remaining_time = total_time
	#update_time_label()
	#status_label.text = "未开始"
#
#func _on_timer_timeout():
	#if remaining_time > 0:
		#remaining_time -= 1
		#update_time_label()
	#else:
		#timer.stop()
		#is_running = false
		#is_paused = false
		#status_label.text = "时间到！"




extends Control

@onready var time_label = $TimeLabel
@onready var status_label = $StatusLabel
@onready var timer = $Timer

# 新增：弹出面板及其内部控件
@onready var popup_panel = $PopupPanel
@onready var minute_input = $PopupPanel/MinuteInput
@onready var start_button = $PopupPanel/StartButton
@onready var pause_button = $PopupPanel/PauseButton
@onready var reset_button = $PopupPanel/ResetButton

# 新增：获取番茄节点
@onready var tomato_node = $"../tomato"

var total_time: int = 25 * 60
var remaining_time: int = 25 * 60
var is_running: bool = false
var is_paused: bool = false
var popup_visible: bool = false

func _ready():
	update_time_label()
	status_label.text = "未开始"
	
	# 默认隐藏弹出面板
	popup_panel.visible = false
	
	start_button.pressed.connect(_on_start_button_pressed)
	pause_button.pressed.connect(_on_pause_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)
	timer.timeout.connect(_on_timer_timeout)
	
	# 连接番茄点击信号
	# 前提：tomato 是 Area2D
	if tomato_node.has_signal("input_event"):
		tomato_node.input_event.connect(_on_tomato_input_event)
	
	update_popup_buttons()

func update_time_label():
	var minutes = remaining_time / 60
	var seconds = remaining_time % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

# 点击番茄：弹出/收起设置面板
func _on_tomato_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_popup()

func toggle_popup():
	popup_visible = not popup_visible
	popup_panel.visible = popup_visible
	
	if popup_visible:
		update_popup_buttons()

# 根据当前状态决定弹窗里显示哪些按钮
func update_popup_buttons():
	if not is_running:
		minute_input.visible = true
		start_button.visible = true
		pause_button.visible = false
		reset_button.visible = false
	else:
		minute_input.visible = false
		start_button.visible = false
		pause_button.visible = true
		reset_button.visible = true
		
		if is_paused:
			pause_button.text = "继续"
		else:
			pause_button.text = "暂停"

func _on_start_button_pressed():
	if not is_running:
		total_time = int(minute_input.value) * 60
		remaining_time = total_time
	
	timer.start()
	is_running = true
	is_paused = false
	status_label.text = "进行中"
	update_time_label()
	
	# 开始后自动关闭弹窗
	popup_panel.visible = false
	popup_visible = false
	
	update_popup_buttons()

func _on_pause_button_pressed():
	if is_running and not is_paused:
		timer.stop()
		is_paused = true
		status_label.text = "已暂停"
	elif is_running and is_paused:
		timer.start()
		is_paused = false
		status_label.text = "进行中"
	
	update_popup_buttons()

func _on_reset_button_pressed():
	timer.stop()
	is_running = false
	is_paused = false
	total_time = int(minute_input.value) * 60
	remaining_time = total_time
	update_time_label()
	status_label.text = "未开始"
	
	# 重置后回到“设置时间”模式
	update_popup_buttons()

func _on_timer_timeout():
	if remaining_time > 0:
		remaining_time -= 1
		update_time_label()
	else:
		timer.stop()
		is_running = false
		is_paused = false
		status_label.text = "时间到！"
		
		# 时间到后允许重新设置
		update_popup_buttons()
