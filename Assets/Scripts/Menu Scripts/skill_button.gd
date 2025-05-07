extends TextureButton

@onready var panel = $Panel
@onready var label = $MarginContainer/Label

var Points = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["Level"]

var lockedCondition = "Locked":
	set(value):
		lockedCondition = value
		label.text = str(lockedCondition)


func _on_pressed() -> void:
	print(Points)
	if Points > 0:
		Points -= 1
		print(Points)
		panel.show_behind_parent = true
	
