extends Node2D

func _ready():
	scale = Vector2(0.1, 0.1)
	
	# 1. 定义几个你想要的固定高度（负数代表向上）
	var heights = [-100] 
	var right_move = 50 # 往右挪多少，你可以改这个数
	
			
	# 2. 随机挑选其中一个
	var random_height = heights[randi() % heights.size()]
	
	var tween = create_tween()
	tween.tween_property(self, "position:x", right_move, 0.01).as_relative()
	# ⭐ 弹一下
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.1)
	
	# ⭐ 上浮（使用选中的固定高度）+ 淡出
	# 使用 as_relative() 可以确保它只在出生点的基础上移动这么多
	tween.parallel().tween_property(self, "position:y", random_height, 0.8).as_relative()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()
