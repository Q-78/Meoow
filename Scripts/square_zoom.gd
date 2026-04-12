extends Node2D

const ANGRY_SOUNDS := [
	preload("res://Assets/sounds/angry/anger1.mp3"),
	preload("res://Assets/sounds/angry/anger2.mp3"),
	preload("res://Assets/sounds/angry/anger3.mp3"),
	preload("res://Assets/sounds/angry/anger4.mp3"),
	preload("res://Assets/sounds/angry/anger5.mp3"),
	preload("res://Assets/sounds/angry/anger6.mp3")
]

@onready var big_cat: AnimatedSprite2D = $BigCat

var is_reacting: bool = false
var angry_player: AudioStreamPlayer

func _ready() -> void:
	randomize()
	big_cat.play("sit")
	_setup_angry_player()

func _setup_angry_player() -> void:
	angry_player = AudioStreamPlayer.new()
	angry_player.name = "AngryPlayer"
	add_child(angry_player)

func _play_random_angry_sound() -> void:
	if angry_player == null or ANGRY_SOUNDS.is_empty():
		return

	angry_player.stop()
	angry_player.stream = ANGRY_SOUNDS[randi() % ANGRY_SOUNDS.size()]
	angry_player.play()
	_stop_angry_sound_after_delay(1.6)

func _stop_angry_sound_after_delay(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if angry_player != null and angry_player.playing:
		angry_player.stop()

func _play_reaction(animation_name: String) -> void:
	if is_reacting:
		return
	is_reacting = true
	big_cat.play(animation_name)
	await get_tree().create_timer(1.7).timeout
	big_cat.play("sit")
	is_reacting = false

# angry 和 sit 来回切换，但 angry 停留更久
func _play_angry_flash() -> void:
	if is_reacting:
		return
	is_reacting = true
	_play_random_angry_sound()

	var total_time := 2.5
	var angry_time := 2.5
	var sit_time := 0.10
	var elapsed := 0.0
	var show_angry := true

	while elapsed < total_time:
		if show_angry:
			big_cat.play("angry")
			await get_tree().create_timer(angry_time).timeout
			elapsed += angry_time
		else:
			big_cat.play("sit")
			await get_tree().create_timer(sit_time).timeout
			elapsed += sit_time

		show_angry = !show_angry

	big_cat.play("sit")
	is_reacting = false

func _on_head_pressed() -> void:
	_play_reaction("happy")

func _on_chin_pressed() -> void:
	_play_reaction("happy")

func _on_paws_pressed() -> void:
	_play_angry_flash()

func _on_tail_pressed() -> void:
	_play_angry_flash()

func _on_back_pressed() -> void:
	GameManager.persist_square_butterfly = true
	get_tree().change_scene_to_file("res://Scenes/square.tscn")

func _on_to_map_pressed() -> void:
	GameManager.clear_square_butterfly_state()
	get_tree().change_scene_to_file("res://Scenes/map.tscn")
