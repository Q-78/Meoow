extends Node2D

@export var speed := 20   # 云移动速度

func _process(delta):
	for cloud in get_children():
		cloud.position.x += speed * delta
		
		# ⭐ 超出屏幕右边 → 回到左边
		if cloud.position.x > get_viewport_rect().size.x + 100:
			cloud.position.x = -100
