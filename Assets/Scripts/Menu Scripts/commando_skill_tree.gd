extends CanvasLayer

func _ready():
	update_perk_points_label()
	connect_skill_buttons(self)

func update_perk_points_label():
	# Updates the perk points counter
	$PerkPointsLabel.text = "Perk points: %d" % GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"]

func connect_skill_buttons(node):
	# This connects the skill buttons to the skill tree
	for child in node.get_children():
		if child is SkillButton:
			child.connect("perk_point_used", Callable(self, "_on_skill_button_used").bind(child))
		connect_skill_buttons(child)

func _on_skill_button_used(button: SkillButton):
	# Tells us when a skill has been bought and what the name is and updates the label
	print("Skill bought:", button.name)
	update_perk_points_label()
	
	# Changes the ability being used
	match button.name:
		"Akimbo":
			GlobalPlayer.upgrade_weapon("AkimboSmg", 1)
			print("Upgraded Akimbo SMG!")
		"DragonsBreath":
			GlobalPlayer.upgrade_weapon("DragonShotgun", 1)
			print("Upgraded DragonsShotgun")

func _on_back_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
