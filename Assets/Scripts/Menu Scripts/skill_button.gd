extends TextureButton
class_name SkillButton

signal perk_point_used

@onready var panel = $Panel
@onready var label = $MarginContainer/Label
@onready var Line = $Line2D
@onready var HoverAnimation = $HoverAnimation

var lockedCondition = "Locked":
	set(value):
		lockedCondition = value
		label.visible = false

var unlocked := false

func _ready():
	if name == "SMG":
		set_unlocked_state(true)
		lockedCondition = "Unlocked"
	
	draw_connection_line()
	update_visuals()
	
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func draw_connection_line():
	# Drawing lines to the parent skill
	if get_parent() is SkillButton:
		var start = panel.get_global_position() + panel.size / 2
		var end = get_parent().get_node("Panel").get_global_position() + get_parent().get_node("Panel").size / 2
		
		var local_start = Line.to_local(start)
		var local_end = Line.to_local(end)
		
		# Ensuring the line is centered
		local_start.x -= 2
		local_end.x -= 2
		
		# Making sure line appears on top of background
		Line.z_index = 5
		
		Line.clear_points()
		Line.add_point(local_start)
		Line.add_point(local_end)
	else:
		Line.hide()

func _on_pressed() -> void:
	if lockedCondition == "Locked":
		if GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] <= 0:
			return
		
		# If the button has a SkillButton parent, check if it's unlocked
		var parent_skill = get_parent()
		if parent_skill is SkillButton and not parent_skill.unlocked:
			print("Cannot unlock", name, " until parent", parent_skill.name, " is unlocked.")
			return
		
		# Skill is unlocked
		GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"] -= 1
		lockedCondition = ""
		unlocked = true
		
		Line.default_color = Color(0.71, 0.0, 0.107)
		
		# Update visuals for child skills (so they switch from locked → preview)
		for skill in get_children():
			if skill is SkillButton:
				skill.update_visuals()
		
		emit_signal("perk_point_used")
		set_unlocked_state(true)

func set_unlocked_state(state: bool):
	unlocked = state
	# Make the locked label disappear if the skill is unlocked
	label.visible = not state
	panel.visible = not state
	update_visuals()

func update_visuals():
	if unlocked:
		# Fully unlocked
		disabled = false
		label.visible = false
		Line.default_color = Color(0.71, 0.0, 0.107)
	else:
		# Still locked, check parent status
		var parent_skill = get_parent()
		if parent_skill is SkillButton:
			if parent_skill.unlocked:
				# Parent unlocked → show preview, skill is clickable
				label.visible = false
				disabled = false
			else:
				# Parent locked → show locked label, disable skill
				label.visible = true
				disabled = true
		else:
			# No parent (root skill) → allow unlocking directly
			label.visible = lockedCondition == "Locked"
			disabled = false

func _on_mouse_entered() -> void:
	HoverAnimation.visible = true
	HoverAnimation.play("default")

func _on_mouse_exited() -> void:
	HoverAnimation.visible = false
