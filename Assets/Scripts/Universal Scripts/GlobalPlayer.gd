extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando"

var ClassData = {
	"Technomancer": {
		"Level": 1, "XP": 0, "PerkPoints": 0, "MoveSpeed": 200,
		"Abilities": ["Technomatic Aura", "Aegis Protocol", "Judgement", "Strength"],
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
		"Level": 1, "XP": 0, "PerkPoints": 0, "MoveSpeed": 150,
		"Abilities": ["TheEmpress", "TheMoon", "TheSun", "TheStar"],
		"SkillTree": {
			"TheMoonUpgrades": [],
			"TheStarUpgrades": [],
			"MutationUpgrades": [],
			"MindUpgrades": []
		}
	}
}

func XPRequiredForLevel(level: int) -> int:
	return 100 * pow(1.2, level - 1)

func AddXP(amount: int):
	var level = ClassData[CurrentClass]["Level"]
	var xp = ClassData[CurrentClass]["XP"] + amount
	var xp_required = XPRequiredForLevel(level)

	while xp >= xp_required:
		xp -= xp_required
		LevelUp()
		level = ClassData[CurrentClass]["Level"]
		xp_required = XPRequiredForLevel(level)

	ClassData[CurrentClass]["XP"] = xp
	UpdateXPBar()

func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	ClassData[CurrentClass]["PerkPoints"] += 1
	UpdateHP()
	UpdatePerkPointUI()

func AddHp(amount: int):
	var level = ClassData[CurrentClass]["Level"]
	var multiplier = 1 + level * 1.5
	PlayerHP = min(PlayerHP + int(amount * multiplier), PlayerHPMax)
	UpdateHealthBar()

func UpdateHP():
	var level = ClassData[CurrentClass]["Level"]
	match CurrentClass:
		"Technomancer":
			PlayerHPMax = 100 + min(level, 10) * 25 + max(level - 10, 0) * 10
		"Commando":
			PlayerHPMax = 100 + min(level, 10) * 50 + max(level - 10, 0) * 25
		"Fleshthing":
			PlayerHPMax = 100 + min(level, 10) * 100 + max(level - 10, 0) * 50

	PlayerHP += 100
	UpdateHealthBar()

func UpdateAbilityList(abilities: Array):
	var ui = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui:
		ui.UpdateAbilityList(abilities)

func UpdateXPBar():
	var ui = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui:
		var level = ClassData[CurrentClass]["Level"]
		ui.XPBar.max_value = XPRequiredForLevel(level)
		ui.XPBar.value = ClassData[CurrentClass]["XP"]

func UpdateHealthBar():
	var ui = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui:
		ui.HealthBar.max_value = PlayerHPMax
		ui.HealthBar.value = PlayerHP

func UnlockSkill(path: String, index: int):
	var skill_tree = ClassData[CurrentClass]["SkillTree"]
	if ClassData[CurrentClass]["PerkPoints"] <= 0:
		print("Not enough PerkPoints.")
		return

	if skill_tree.has(path) and index >= 0 and index < skill_tree[path].size():
		if not skill_tree[path][index]:
			skill_tree[path][index] = true
			ClassData[CurrentClass]["PerkPoints"] -= 1
			print("Unlocked skill:", path, "Index:", index)
			UpdatePerkPointUI()
		else:
			print("Skill already unlocked.")
	else:
		print("Invalid skill unlock attempt.")

func UpdatePerkPointUI():
	var ui = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui:
		ui.UpdatePerkPoints(ClassData[CurrentClass]["PerkPoints"])
