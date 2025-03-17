extends Sprite2D

func _ready():
	update_size()
	get_viewport().connect("size_changed", Callable(self, "update_size"))  # Adjust on resize

func update_size():
	var screen_size = get_viewport_rect().size  # Get window size

	if texture:
		var texture_size = texture.get_size()  # Get sprite texture size

		# Scale it so it fully covers the screen
		scale.x = screen_size.x / texture_size.x
		scale.y = screen_size.y / texture_size.y

		# Move sprite to the top-left
		position = Vector2(0, 0)
		centered = false  # Ensure no auto-centering
