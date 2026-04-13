extends Node

var intimacy = 0

# Square butterfly persistence only between square <-> square_zoom.
var persist_square_butterfly: bool = false
var square_butterfly_state := {}
var square_chase_time_left: float = -1.0

func clear_square_butterfly_state() -> void:
	persist_square_butterfly = false
	square_butterfly_state = {}
	square_chase_time_left = -1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
