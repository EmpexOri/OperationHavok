extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando"

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
		"Level": 1, "XP": 0, "PerkPoints": 5, "PerPointsSpent": 0, "MoveSpeed": 150,
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

func XPRequiredForLevel(Level: int) -> int:
	return 100 * pow(1.2, Level - 1)

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
	UpdateXPBar()

func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	ClassData[CurrentClass]["PerkPoints"] += 1
	UpdateHP()
	UpdatePerkPointUI()

func AddHp(Amount: int):
	var Level = ClassData[CurrentClass]["Level"]
	var HpGainMultiplier = 1 + ((Level) * 1.15)
	var AdjustedAmount = int(Amount * HpGainMultiplier)
	PlayerHP = min(PlayerHP + AdjustedAmount, PlayerHPMax)
	UpdateHealthBar()

func UpdateHP():
	var Level = ClassData[CurrentClass]["Level"]
	var base_hp = 100
	var hp = base_hp

	for i in range(1, Level + 1):
		if i <= 5:
			hp += 20  # Big boost for early levels
		elif i <= 10:
			hp += 15
		elif i <= 15:
			hp += 10
		elif i <= 20:
			hp += 5
		else:
			hp += 2  # Very small boost for ultra-high levels

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

# Grants the player N levels immediately (for debugging)
func GiveDebugLevels(amount: int):
	for i in range(amount):
		LevelUp()
	print("Debug: Gave ", amount, " levels to ", CurrentClass, 
		". New level: ", ClassData[CurrentClass]["Level"])
