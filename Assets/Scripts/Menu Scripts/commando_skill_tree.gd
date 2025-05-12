extends CanvasLayer

func _ready():
	update_perk_points_label()
	connect_skill_buttons(self)

func update_perk_points_label():
	$PerkPointsLabel.text = "Perk points: %d" % GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"]

func connect_skill_buttons(node):
	for child in node.get_children():
		if child is SkillButton:
			child.connect("perk_point_used", Callable(self, "update_perk_points_label"))
		connect_skill_buttons(child)  # Recursively connect nested children
