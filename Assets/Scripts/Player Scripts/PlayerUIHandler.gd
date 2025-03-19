extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var XPBar: TextureProgressBar = $UIContainer/XPBar

func _ready():
	UpdateHealthBar()
	UpdateXPBar()

func _process(_delta):
	UpdateHealthBar()
	UpdateXPBar()

func UpdateHealthBar():
	HealthBar.max_value = Global.PlayerHPMax
	HealthBar.value = Global.PlayerHP

func UpdateXPBar():
	var CurrentClass = Global.CurrentClass
	var Level = Global.ClassData[CurrentClass]["Level"]
	var XP = Global.ClassData[CurrentClass]["XP"]
	var XPNeeded = Global.XPRequiredForLevel(Level)

	XPBar.max_value = XPNeeded
	XPBar.value = XP
