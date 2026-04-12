extends Node

const LOGIN_SCENE := "res://Scenes/auth.tscn"
const SPLASH_SCENE := "res://Scenes/start_scene.tscn"

func _ready() -> void:
	SceneMemory.load_data()

	if not AccountManager.is_logged_in():
		call_deferred("_go_to_scene", LOGIN_SCENE)
		return

	if SceneMemory.has_last_scene():
		var last_scene := SceneMemory.get_last_scene()
		if ResourceLoader.exists(last_scene):
			call_deferred("_go_to_scene", last_scene)
			return

	call_deferred("_go_to_scene", SPLASH_SCENE)

func _go_to_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
