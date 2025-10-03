extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var LevelLabel: Label = $UIContainer/LevelLabel
@onready var ClassLabel: Label = $UIContainer/ClassLabel
@onready var XPCircle: TextureProgressBar = $UIContainer/TextureProgressBar
@onready var DodgeBar: TextureProgressBar = $UIContainer/DodgeBar 
@onready var ScoreLabel: Label = $UIContainer/ScoreLabel

var flash_tween: Tween = null

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

func PlayLevelUpEffect():
	if HealthBar:
		var tween := create_tween()
		var original_color := HealthBar.self_modulate
		var gold_color := Color(1.0, 0.85, 0.0, 1.0)
		tween.tween_property(HealthBar, "self_modulate", gold_color, 0.25)
		tween.tween_property(HealthBar, "self_modulate", original_color, 0.25).set_delay(0.75)

func FlashScreen(color: Color, duration: float = 0.2, times: int = 1):
	var flash_path = "UIContainer/ScreenFlash"
	if not has_node(flash_path):
		print("ScreenFlash node missing at path: ", flash_path)
		return
	
	var flash_rect: ColorRect = get_node(flash_path)
	flash_rect.color = color
	flash_rect.visible = true
	flash_rect.modulate.a = 0.0 

	if flash_tween:
		flash_tween.kill()
	flash_tween = create_tween()

	for i in range(times):
		flash_tween.tween_property(flash_rect, "modulate:a", 0.2, duration/2)
		flash_tween.tween_property(flash_rect, "modulate:a", 0.0, duration/2)

	flash_tween.tween_callback(Callable(flash_rect, "hide"))
