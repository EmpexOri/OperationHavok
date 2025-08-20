extends OptionButton

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	# Populate dropdown with options
	for r in resolutions:
		add_item("%dx%d" % [r.x, r.y])

	# Load from global or default
	select(Global.resolution_index)

	# Connect signal
	connect("item_selected", Callable(self, "_on_resolution_selected"))

func _on_resolution_selected(index: int):
	Global.resolution_index = index
	Global.apply_display_settings()
