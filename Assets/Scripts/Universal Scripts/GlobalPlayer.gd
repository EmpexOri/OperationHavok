extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando"
var HelpXP: int = 0
var total_enemies_killed: int = 0

var current_level_scene_path: String = ""

var weapon_upgrades = {
	1: "Smg",
	2: "Shotgun"
}

var ClassData = {
	"Technomancer": {
		"Level": 4, "XP": 0, "PerkPoints": 0, "PerPointsSpent": 0, "MoveSpeed": 150, 
		"Abilities": [], "UnlockedAbilities": []
	},
	"Commando": {
		"Level": 0, "XP": 0, "PerkPoints": 0, "PerPointsSpent": 0, "MoveSpeed": 150,
		"Abilities": ["SwapWeapons", "GrenadeThrow", "RocketLauncher"], "UnlockedAbilities": ["SMG", "Grenade", "Minigun"]
	},
	"Fleshthing": {
		"Level": 4, "XP": 0, "PerkPoints": 0, "PerPointsSpent": 0, "MoveSpeed": 150, 
		"Abilities": [], "UnlockedAbilities": []
	}
}

var AbilityListTechnomancer = ["Technomatic Aura", "Aegis Protocol", "Judgement", "Strength"]
var AbilityListCommando = ["SwapWeapons", "GrenadeThrow", "TyphoonCannon"]
var AbilityListFleshthing = ["TheEmpress", "TheMoon", "TheSun", "TheStar"]

var current_respawn_position: Vector2 = Vector2.ZERO

func XPRequiredForLevel(Level: int) -> int:
	return 50 * pow(1.2, Level - 1)

func AddXP(Amount: int):
	var Level = ClassData[CurrentClass]["Level"]
	var CurrentXP = ClassData[CurrentClass]["XP"]
	var XPNecessary = XPRequiredForLevel(Level)

	CurrentXP += Amount
	while CurrentXP >= XPNecessary:
		CurrentXP -= XPNecessary
		LevelUp()
		XPNecessary = XPRequiredForLevel(ClassData[CurrentClass]["Level"])

	ClassData[CurrentClass]["XP"] = CurrentXP
	AddHelpXP(Amount*100)
	UpdateXPBar()
	
func AddHelpXP(amount: int):
	HelpXP += amount
	#print("Added HelpXP, new total:", HelpXP)
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.UpdateScore()

func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	ClassData[CurrentClass]["PerkPoints"] += 1
	UpdateHP()
	UpdatePerkPointUI()
	
	var UIHandler = get_node_or_null("/root/World/PlayerUI")
	if UIHandler:
		UIHandler.FlashScreen(Color(1.0, 0.85, 0.0), 0.3, 1)
		UIHandler.PlayLevelUpEffect()
		
	var audio = get_node_or_null("/root/GlobalAudioController")
	if audio and audio.has_method("PlayLevelUpSound"):
		audio.PlayLevelUpSound()

func AddHp(Amount: int):
	var Level = ClassData[CurrentClass]["Level"]
	var HpGainMultiplier = 1.5
	var AdjustedAmount = int(Amount * HpGainMultiplier)
	PlayerHP = min(PlayerHP + AdjustedAmount, PlayerHPMax)
	UpdateHealthBar()

func UpdateHP():
	var Level = ClassData[CurrentClass]["Level"]
	var base_hp = 100

	var hp = base_hp + min(Level, 10) * 5

	PlayerHPMax = hp
	PlayerHP = min(PlayerHP + int(hp * 0.2), PlayerHPMax) 
	UpdateHealthBar()

#func UnlockAbilities():
#	var Level = ClassData[CurrentClass]["Level"]
#	var FullAbilityList = []
#	
#	match CurrentClass:
#		"Technomancer":
#			FullAbilityList = AbilityListTechnomancer
#		"Commando":
#			FullAbilityList = AbilityListCommando
#		"Fleshthing":
#			FullAbilityList = AbilityListFleshthing
#
#	var AbilitiesUnlocked = FullAbilityList.slice(0, min(Level, FullAbilityList.size()))  # Unlock abilities based on level
#	ClassData[CurrentClass]["Abilities"] = AbilitiesUnlocked
#	UpdateAbilityList()

func UpdateAbilityList():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.UpdateAbilityList(ClassData[CurrentClass]["Abilities"])

func UpdateXPBar():
	var Level = ClassData[CurrentClass]["Level"]
	var XPNecessary = XPRequiredForLevel(Level)
	var XP = ClassData[CurrentClass]["XP"]

	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.XPBar.max_value = XPNecessary
		UIHandler.XPBar.value = XP

func UpdateHealthBar():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.HealthBar.max_value = PlayerHPMax
		UIHandler.HealthBar.value = PlayerHP


func UpdatePerkPointUI():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler and UIHandler.has_method("UpdatePerkPoints"):
		UIHandler.UpdatePerkPoints(ClassData[CurrentClass]["PerkPoints"])

func upgrade_weapon(weapon_name: String, slot: int) -> void:
	if not WeaponData.weapon_scenes.has(weapon_name):
		print("Invalid weapon upgrade: ", weapon_name)
		return
	
	weapon_upgrades[slot] = weapon_name
	print("GlobalPlayer upgraded weapon slot ", slot, " to ", weapon_name)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("DebugInput"):
		GiveDebugLevels(5)

# Grants the player levels immediately (for debugging)
func GiveDebugLevels(amount: int):
	for i in range(amount):
		LevelUp()
	print("Debug: Gave ", amount, " levels to ", CurrentClass, 
		". New level: ", ClassData[CurrentClass]["Level"])

func reset_match_counters():
	total_enemies_killed = 0

func set_current_level_scene(scene_path: String) -> void:
	current_level_scene_path = scene_path

func get_current_level_scene() -> String:
	return current_level_scene_path

func restart_level():
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	SmearCanvas.reset()

	PlayerHP = PlayerHPMax

	if get_tree().paused:
		get_tree().paused = false

	# Try to clear runtime objects
	var level_root = get_tree().get_root().get_child(0)  # usually your level scene is the first child under SceneTree root
	if level_root and level_root.has_method("clear_runtime_objects"):
		level_root.clear_runtime_objects()
		print("Cleared runtime objects.")

	# Reload the current scene
	if current_level_scene_path != "":
		get_tree().change_scene_to_file(current_level_scene_path)
