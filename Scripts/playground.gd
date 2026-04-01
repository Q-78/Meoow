extends Node2D

@export var intimacy_label : Label

@onready var cat_node = $cat001
@onready var bowl_node = $bowl

func _ready() -> void:
	bowl_node.feeding_finished.connect(_on_bowl_feeding_finished)
	cat_node.eat_finished.connect(_on_cat_eat_finished)
	pass

func _process(delta: float) -> void:
	pass

func _on_bowl_feeding_finished() -> void:
	var target_pos = $bowl/Marker2D.global_position
	print("主场景传给猫的目标点:", target_pos)
	cat_node.go_to_eat(target_pos)

func _on_cat_eat_finished() -> void:
	bowl_node.set_empty()


	
	
	


func _on_to_map_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
