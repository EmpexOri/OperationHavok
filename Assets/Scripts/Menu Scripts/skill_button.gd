extends TextureButton

@onready var panel = $Panel
@onready var label = $MarginContainer/Label

#var Points = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"]
var Points = 3

var lockedCondition = "Locked":
	set(value):
		lockedCondition = value
		label.text = str(lockedCondition)


func _on_pressed() -> void:
	if Points > 0:
		Points -= 1
		print(Points)
		panel.show_behind_parent = true
