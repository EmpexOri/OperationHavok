extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var XPBar: TextureProgressBar = $UIContainer/XPBar
@onready var LevelLabel: Label = $UIContainer/LevelLabel
@onready var ClassLabel: Label = $UIContainer/ClassLabel

func _ready():
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()

func _process(_delta):
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()

func UpdateHealthBar():
	print("HP:", Global.PlayerHP, " / ", Global.PlayerHPMax)
	HealthBar.max_value = Global.PlayerHPMax
	HealthBar.value = Global.PlayerHP

func UpdateXPBar():
	var CurrentClass = Global.CurrentClass
	var Level = Global.ClassData[CurrentClass]["Level"]
	var XP = Global.ClassData[CurrentClass]["XP"]
	var XPNeeded = Global.XPRequiredForLevel(Level)

	print("XP:", XP, " / ", XPNeeded)
	XPBar.max_value = XPNeeded
	XPBar.value = XP

func UpdateClassInfo():
	var CurrentClass = Global.CurrentClass
	var Level = Global.ClassData[CurrentClass]["Level"]

	LevelLabel.text = "Level: " + str(Level)
	ClassLabel.text = "Class: " + CurrentClass
