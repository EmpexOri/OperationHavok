extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var LevelLabel: Label = $UIContainer/LevelLabel
@onready var ClassLabel: Label = $UIContainer/ClassLabel
@onready var XPCircle: TextureProgressBar = $UIContainer/TextureProgressBar

func _ready():
	await get_tree().process_frame  # Ensures UI elements are ready before updating
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()

func _process(_delta):
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()

func UpdateHealthBar():
	if HealthBar:
		#print("HP:", Global.PlayerHP, " / ", Global.PlayerHPMax)
		HealthBar.max_value = GlobalPlayer.PlayerHPMax
		HealthBar.value = GlobalPlayer.PlayerHP

func UpdateXPBar():
	if XPCircle:
		var CurrentClass = GlobalPlayer.CurrentClass
		var Level = GlobalPlayer.ClassData[CurrentClass]["Level"]
		var XP = GlobalPlayer.ClassData[CurrentClass]["XP"]
		var XPNeeded = GlobalPlayer.XPRequiredForLevel(Level)

		#print("XP:", XP, " / ", XPNeeded)
		XPCircle.max_value = XPNeeded
		XPCircle.value = XP

func UpdateClassInfo():
	if LevelLabel and ClassLabel:
		var CurrentClass = GlobalPlayer.CurrentClass
		var Level = GlobalPlayer.ClassData[CurrentClass]["Level"]

		LevelLabel.text = "Level: " + str(Level)
		ClassLabel.text = "Class: " + CurrentClass
