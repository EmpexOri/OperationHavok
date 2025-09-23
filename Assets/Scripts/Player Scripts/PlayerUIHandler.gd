extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var LevelLabel: Label = $UIContainer/LevelLabel
@onready var ClassLabel: Label = $UIContainer/ClassLabel
@onready var XPCircle: TextureProgressBar = $UIContainer/TextureProgressBar
@onready var DodgeBar: TextureProgressBar = $UIContainer/DodgeBar 
@onready var ScoreLabel: Label = $UIContainer/ScoreLabel

func _ready():
	add_to_group("PlayerUI")
	await get_tree().process_frame
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()
	UpdateDodgeBar(1.0)
	UpdateScore()

func _process(_delta):
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()
	UpdateScore()  

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

func UpdateDodgeBar(ratio: float):
	if DodgeBar:
		# Clamp between 0 and 1 just in case
		DodgeBar.value = clamp(ratio, 0.0, 1.0)

func UpdateScore():
	if ScoreLabel:
		var score = GlobalPlayer.HelpXP  
		ScoreLabel.text = "Score: " + str(score)
