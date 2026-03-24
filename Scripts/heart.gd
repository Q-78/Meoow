extends Node2D

func _ready():
	scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	
	# ⭐ 先“弹一下”
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.5)
	
	# ⭐ 再上浮 + 淡出（并行）
	tween.parallel().tween_property(self, "position:y", position.y - 30, 0.8)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	
	await tween.finished
	queue_free()
