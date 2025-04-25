extends HSlider


func _on_value_changed(value: float) -> void:
	GlobalBrightnessCanvas.environment.adjustment_brightness = value
