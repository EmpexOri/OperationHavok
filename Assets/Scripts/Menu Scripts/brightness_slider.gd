extends HSlider

func _process(delta):
	# Only move the slider if it's currently selected
	if not has_focus():
		return

	# Making the slider steps faster for controller
	var move_speed = 1.5
	var input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Only update it if there's actual input
	if abs(input) > 0.1:
		value = clamp(value + input * move_speed * delta, min_value, max_value)

# Called when the slider value changes
func _on_value_changed(value: float) -> void:
	GlobalBrightness.brightness = value  
	# Update the canvas brightness
	GlobalBrightnessCanvas.environment.adjustment_brightness = value

# Called when the scene is ready, ensuring the slider is set to the global value
func _ready() -> void:
	value = GlobalBrightness.brightness
