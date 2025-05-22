extends TextureButton
class_name SkillButton

signal perk_point_used

@onready var panel = $Panel
@onready var label = $MarginContainer/Label
@onready var Line = $Line2D

var lockedCondition = "Locked":
	set(value):
		lockedCondition = value
		label.text = str(lockedCondition)

func _ready():
	# Drawing lines between the skill tree buttons
	if get_parent() is SkillButton:
		var start = panel.get_global_position() + panel.size / 2
		var end = get_parent().get_node("Panel").get_global_position() + get_parent().get_node("Panel").size / 2

		var local_start = Line.to_local(start)
		var local_end = Line.to_local(end)
		
		local_start.x += 4
		local_end.x += 4

		Line.clear_points()
		Line.add_point(local_start)
		Line.add_point(local_end)
	else:
		Line.hide()

	# Updating the label
	label.text = str(lockedCondition)

func _on_pressed() -> void:
	# Checking whether the button has been unlocked yet and if it hasnt, let the player unlock it
	if GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] > 0 and lockedCondition == "Locked":
		GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] -= 1
		panel.show_behind_parent = true
		lockedCondition = ""
		
		Line.default_color = Color(0.71, 0.0, 0.107)
		
		# Only unlock the next tier once first tier has been unlocked
		var skills = get_children()
		for skill in skills:
			if skill is SkillButton:
				skill.disabled = false
		
		emit_signal("perk_point_used")
