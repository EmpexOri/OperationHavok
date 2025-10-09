extends Node

@onready var HealthBar: TextureProgressBar = $UIContainer/HealthBar
@onready var LevelLabel: Label = $UIContainer/LevelLabel
@onready var ClassLabel: Label = $UIContainer/ClassLabel
@onready var XPCircle: TextureProgressBar = $UIContainer/TextureProgressBar
@onready var DodgeBar: TextureProgressBar = $UIContainer/DodgeBar 
@onready var ScoreLabel: Label = $UIContainer/ScoreLabel
@onready var LevelTimeLabel: Label = $UIContainer/LevelTimeLabel  # make sure this node exists in scene
@onready var LevelUpIndicator = $UIContainer/SelectLevelUp

var flash_tween: Tween = null
var time_update_accumulator: float = 0.0  # used to throttle timer text updates

func _ready() -> void:
	add_to_group("PlayerUI")
	await get_tree().process_frame  # ensures GlobalPlayer & UIContainer are ready

	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()
	UpdateDodgeBar(1.0)
	UpdateScore()
	UpdateLevelTime()  # initialize immediately

# Note: use _delta here (matches the parameter name) so you don't get "identifier not declared"
func _process(_delta: float) -> void:
	UpdateHealthBar()
	UpdateXPBar()
	UpdateClassInfo()
	UpdateScore()

	# 🕒 Update timer display every 0.2s for efficiency & frame safety
	time_update_accumulator += _delta
	if time_update_accumulator >= 0.2:
		UpdateLevelTime()
		time_update_accumulator = 0.0

func UpdateHealthBar() -> void:
	if HealthBar:
		HealthBar.max_value = GlobalPlayer.PlayerHPMax
		HealthBar.value = GlobalPlayer.PlayerHP

func UpdateXPBar() -> void:
	if XPCircle:
		var CurrentClass = GlobalPlayer.CurrentClass
		var Level = GlobalPlayer.ClassData[CurrentClass]["Level"]
		var XP = GlobalPlayer.ClassData[CurrentClass]["XP"]
		var XPNeeded = GlobalPlayer.XPRequiredForLevel(Level)
		XPCircle.max_value = XPNeeded
		XPCircle.value = XP

func UpdateClassInfo() -> void:
	if LevelLabel and ClassLabel:
		var CurrentClass = GlobalPlayer.CurrentClass
		var Level = GlobalPlayer.ClassData[CurrentClass]["Level"]
		LevelLabel.text = "Level: " + str(Level)
		ClassLabel.text = "Class: " + CurrentClass

func UpdateDodgeBar(ratio: float) -> void:
	if DodgeBar:
		DodgeBar.value = clamp(ratio, 0.0, 1.0)

func UpdateScore() -> void:
	if ScoreLabel:
		var score = GlobalPlayer.HelpXP  
		ScoreLabel.text = "Score: " + str(score)

func UpdateLevelTime():
	if LevelTimeLabel:
		var total_seconds = int(GlobalPlayer.Level_Time)
		var minutes = total_seconds / 60
		var seconds = total_seconds % 60
		LevelTimeLabel.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

func PlayLevelUpEffect() -> void:
	if HealthBar:
		var tween := create_tween()
		var original_color := HealthBar.self_modulate
		var gold_color := Color(1.0, 0.85, 0.0, 1.0)
		tween.tween_property(HealthBar, "self_modulate", gold_color, 0.25)
		tween.tween_property(HealthBar, "self_modulate", original_color, 0.25).set_delay(0.75)
	
	# Level up indicator flash (Don't question my methods)
	LevelUpIndicator.visible = true
	await get_tree().create_timer(0.6).timeout
	LevelUpIndicator.visible = false
	await get_tree().create_timer(0.3).timeout
	LevelUpIndicator.visible = true
	await get_tree().create_timer(0.6).timeout
	LevelUpIndicator.visible = false
	await get_tree().create_timer(0.3).timeout
	LevelUpIndicator.visible = true
	await get_tree().create_timer(0.6).timeout
	LevelUpIndicator.visible = false
	await get_tree().create_timer(0.3).timeout
	LevelUpIndicator.visible = true
	await get_tree().create_timer(0.6).timeout
	LevelUpIndicator.visible = false
	await get_tree().create_timer(0.3).timeout
	LevelUpIndicator.visible = true
	await get_tree().create_timer(0.6).timeout
	LevelUpIndicator.visible = false

func FlashScreen(color: Color, duration: float = 0.2, times: int = 1) -> void:
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
		flash_tween.tween_property(flash_rect, "modulate:a", 0.2, duration / 2)
		flash_tween.tween_property(flash_rect, "modulate:a", 0.0, duration / 2)

	flash_tween.tween_callback(Callable(flash_rect, "hide"))
