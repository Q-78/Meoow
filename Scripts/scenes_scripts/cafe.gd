extends Node2D

func _ready() -> void:
	SceneMemory.set_last_scene(scene_file_path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		SceneMemory.set_last_scene(scene_file_path)
	elif what == NOTIFICATION_EXIT_TREE:
		SceneMemory.set_last_scene(scene_file_path)

func _on_to_map_pressed() -> void:
	var next_scene := "res://Scenes/map.tscn"
	SceneMemory.set_last_scene(next_scene)
	PawTransition.transition_to_scene(next_scene)
	#get_tree().change_scene_to_file(next_scene)
