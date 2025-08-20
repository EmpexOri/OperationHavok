extends Button

var is_fullscreen := false

func _ready():
	text = "Toggle Fullscreen"
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	is_fullscreen = !is_fullscreen
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		text = "Windowed Mode"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		text = "Fullscreen Mode"
