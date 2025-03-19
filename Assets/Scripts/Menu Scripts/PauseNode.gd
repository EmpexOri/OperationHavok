extends Node

func _on_resume_button_pressed() -> void:
	if get_tree().paused:
		get_tree().paused = false


func _on_controls_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()
