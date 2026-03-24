extends Control

@onready var time_label = $TimeLabel
@onready var week_label = $WeekLabel
@onready var date_label = $DateLabel

func _ready():
	update_time()
	
	# 每秒更新一次
	var timer = Timer.new()
	timer.wait_time = 1
	timer.autostart = true
	timer.timeout.connect(update_time)
	add_child(timer)


func update_time():
	var now = Time.get_datetime_dict_from_system()
	
	var year = now.year
	var month = now.month
	var day = now.day
	
	var hour = now.hour
	var minute = now.minute
	var weekday = now.weekday   # 0=周日
	
	# ===== 24小时制 =====
	var time_str = "%02d:%02d" % [hour, minute]
	
	# ===== 日期 =====
	var date_str = "%d年%d月%d日" % [year, month, day]
	
	# ===== 星期 =====
	var week_map = ["星期日","星期一","星期二","星期三","星期四","星期五","星期六"]
	var week_str = week_map[weekday]
	
	# ===== 更新UI =====
	time_label.text = time_str
	week_label.text = week_str
	date_label.text = date_str
