extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando"

var ClassData = {
	"Technomancer": {
		"Level": 1, "XP": 0, "PerkPoints": 0, "MoveSpeed": 200, "Abilities": [],
		"SkillTree": {
			"TechAuraUpgrades": [],
			"JudgementUpgrades": [],
			"ShieldUpgrades": [],
			"UtilityUpgrades": []
		}
	},
	"Commando": {
		"Level": 1, "XP": 0, "PerkPoints": 0, "MoveSpeed": 150,
		"Abilities": ["SwapWeapons", "SniperBeam", "WeaponOverCharge"],
		"SkillTree": {
			"SMG Upgrades": [false, false, false],
			"Shotgun Upgrades": [false, false, false],
			"Grenade Upgrades": [false, false, false],
			"Utility Upgrades": [false, false, false]
		}
	},
	"Fleshthing": {
		"Level": 1, "XP": 0, "PerkPoints": 0, "MoveSpeed": 150, "Abilities": [],
		"SkillTree": {
			"TheMoonUpgrades": [],
			"TheStarUpgrades": [],
			"MutationUpgrades": [],
			"MindUpgrades": []
		}
	}
}

var AbilityListTechnomancer = ["Technomatic Aura", "Aegis Protocol", "Judgement", "Strength"]
var AbilityListCommando = ["SwapWeapons", "SniperBeam", "WeaponOverCharge"]
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
	UnlockAbilities()
	UpdateHP()
	UpdatePerkPointUI()

func AddHp(Amount: int):
	var Level = ClassData[CurrentClass]["Level"]
	var HpGainMultiplier = 1 + ((Level) * 1.5)
	var AdjustedAmount = int(Amount * HpGainMultiplier)
	PlayerHP = min(PlayerHP + AdjustedAmount, PlayerHPMax)
	UpdateHealthBar()

func UpdateHP():
	var Level = ClassData[CurrentClass]["Level"]
	if CurrentClass == "Technomancer":
		PlayerHPMax = 100 + min(Level, 10) * 25 + max(Level - 10, 0) * 10
	elif CurrentClass == "Commando":
		PlayerHPMax = 100 + min(Level, 10) * 50 + max(Level - 10, 0) * 25
	elif CurrentClass == "Fleshthing":
		PlayerHPMax = 100 + min(Level, 10) * 100 + max(Level - 10, 0) * 50
	
	PlayerHP += 100
	UpdateHealthBar()

func UnlockAbilities():
	var Level = ClassData[CurrentClass]["Level"]
	var FullAbilityList = []
	
	match CurrentClass:
		"Technomancer":
			FullAbilityList = AbilityListTechnomancer
		"Commando":
			FullAbilityList = AbilityListCommando
		"Fleshthing":
			FullAbilityList = AbilityListFleshthing

	var AbilitiesUnlocked = FullAbilityList.slice(0, min(Level, FullAbilityList.size()))  # Unlock abilities based on level
	ClassData[CurrentClass]["Abilities"] = AbilitiesUnlocked
	UpdateAbilityList()

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

func UnlockSkill(path: String, index: int):
	var skill_tree = ClassData[CurrentClass]["SkillTree"]

	if ClassData[CurrentClass]["PerkPoints"] <= 0:
		print("Not enough PerkPoints.")
		return

	if skill_tree.has(path) and index >= 0 and index < skill_tree[path].size():
		if not skill_tree[path][index]:
			# Check if the previous skill in the path is unlocked (for sequential unlocking)
			if index > 0 and not skill_tree[path][index - 1]:
				print("Previous skill must be unlocked first.")
				return
			
			# Unlock the skill and decrement PerkPoints
			skill_tree[path][index] = true
			ClassData[CurrentClass]["PerkPoints"] -= 1
			print("Unlocked skill:", path, "Index:", index)
			UpdatePerkPointUI()
		else:
			print("Skill already unlocked.")
	else:
		print("Invalid skill unlock attempt.")

func UpdatePerkPointUI():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler and UIHandler.has_method("UpdatePerkPoints"):
		UIHandler.UpdatePerkPoints(ClassData[CurrentClass]["PerkPoints"])
