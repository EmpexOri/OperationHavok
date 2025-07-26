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

var unlocked := false

func _ready():
	draw_connection_line()
	update_visuals()

func draw_connection_line():
	# Drawing lines to the parent skill
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

func _on_pressed() -> void:
	if GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] <= 0:
		return
	
	# If the button has a SkillButton parent, check if it's unlocked
	var parent_skill = get_parent()
	if parent_skill is SkillButton and not parent_skill.unlocked:
		print("Cannot unlock", name, " until parent", parent_skill.name, " is unlocked.")
		return
	
	# Skill is unlocked
	GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] -= 1
	panel.show_behind_parent = true
	lockedCondition = ""
	unlocked = true
	
	Line.default_color = Color(0.71, 0.0, 0.107)
	
	# Enable second tier skills
	for skill in get_children():
		if skill is SkillButton:
			skill.disabled = false
	
	emit_signal("perk_point_used")

func set_unlocked_state(state: bool):
	unlocked = state
	lockedCondition = "" if unlocked else "Locked"
	update_visuals()

func update_visuals():
	label.text = str(lockedCondition)
	
	if unlocked:
		panel.show_behind_parent = true
		disabled = false
		Line.default_color = Color(0.71, 0.0, 0.107)
	else:
		panel.show_behind_parent = false
		disabled = false
