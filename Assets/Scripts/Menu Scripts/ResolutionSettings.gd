extends Button

# Available resolutions
var resolutions = [
	Vector2i(1280, 720),   # 720p
	Vector2i(1920, 1080),  # 1080p
	Vector2i(2560, 1440)   # 1440p
]

var current_index := 1 # Start at 1080p (index 1)

func _ready():
	text = "Resolution: %dx%d" % [resolutions[current_index].x, resolutions[current_index].y]
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed():
	current_index = (current_index + 1) % resolutions.size()
	var new_res = resolutions[current_index]
	DisplayServer.window_set_size(new_res)
	text = "Resolution: %dx%d" % [new_res.x, new_res.y]
