extends TextureButton
class_name SkillButton

signal perk_point_used

@onready var panel = $Panel
@onready var label = $MarginContainer/Label

var lockedCondition = "Locked":
	set(value):
		lockedCondition = value
		label.text = str(lockedCondition)

func _ready():
	label.text = str(lockedCondition)

func _on_pressed() -> void:
	if GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] > 0 and lockedCondition == "Locked":
		GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] -= 1
		panel.show_behind_parent = true
		lockedCondition = ""
		emit_signal("perk_point_used")
