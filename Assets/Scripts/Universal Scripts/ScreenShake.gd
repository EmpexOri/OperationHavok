extends Node

var camera: Camera2D = null

func register_camera(cam: Camera2D) -> void:
	camera = cam

func shake(intensity: float = 8.0, duration: float = 0.5) -> void:
	if camera:
		camera.shake(intensity, duration)
