extends Node

const SAVE_PATH := "user://scene_memory.cfg"
const DEFAULT_SCENE := ""

var last_scene_path: String = DEFAULT_SCENE

func _ready() -> void:
	load_data()

func load_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)

	if err == OK:
		last_scene_path = str(config.get_value("scene", "last_scene_path", DEFAULT_SCENE))
	else:
		last_scene_path = DEFAULT_SCENE

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("scene", "last_scene_path", last_scene_path)
	config.save(SAVE_PATH)

func set_last_scene(scene_path: String) -> void:
	if scene_path.strip_edges() == "":
		return

	last_scene_path = scene_path
	save_data()
	print("SceneMemory: 已记录上次场景 -> ", last_scene_path)

func get_last_scene() -> String:
	return last_scene_path

func has_last_scene() -> bool:
	return last_scene_path.strip_edges() != ""

func clear_data() -> void:
	last_scene_path = DEFAULT_SCENE
	save_data()
	print("SceneMemory: 已清除场景记录")
