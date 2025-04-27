extends Label

func _process(delta):
	# Get FPS from Engine singleton
	var fps = Engine.get_frames_per_second()
	text = "FPS: %d" % fps
