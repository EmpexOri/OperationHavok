extends HSlider

# Called when the slider value changes
func _on_value_changed(value: float) -> void:
	GlobalBrightness.brightness = value  # Update the global brightness value
	# Update the canvas brightness too
	GlobalBrightnessCanvas.environment.adjustment_brightness = value

# Called when the scene is ready, ensuring the slider is set to the global value
func _ready() -> void:
	value = GlobalBrightness.brightness
