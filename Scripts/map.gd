extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_playground_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/playground.tscn")


func _on_library_button_up() -> void:
	get_tree().change_scene_to_file("res://Scenes/library_scene.tscn")


func _on_dasha_river_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/dasha_river.tscn")


func _on_tree_hole_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/tree_hole.tscn")


func _on_bajiudong_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/square.tscn")
