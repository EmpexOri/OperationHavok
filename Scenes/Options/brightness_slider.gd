extends HSlider


func _on_value_changed(value: float) -> void:
	GlobalBrightness.environment.adjustment_brightness = value
