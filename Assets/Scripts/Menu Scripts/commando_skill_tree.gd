extends CanvasLayer

func _ready():
	update_perk_points_label()

func update_perk_points_label():
	var perk_points = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["PerkPoints"]
	$PerkPointsLabel.text = "Perk points: %d" % perk_points


func _on_back_button_pressed() -> void:
	GlobalAudioController.ClickSound()
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")
