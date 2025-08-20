extends Button

var is_fullscreen := false

func _ready():
	text = "Toggle Fullscreen"
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	Global.fullscreen_enabled = !Global.fullscreen_enabled
	Global.apply_display_settings()
