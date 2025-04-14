extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando"

var ClassData = {
	"Technomancer": {"Level": 1, "XP": 0, "MoveSpeed": 200, "Perks": []},
	"Commando": {"Level": 1, "XP": 0, "MoveSpeed": 150, "Perks": ["SwapWeapons", "SniperBeam", "WeaponOverCharge"]},
	"Fleshthing": {"Level": 1, "XP": 0, "MoveSpeed": 150, "Perks": []}
}

var PerkListTechnomancer = ["Technomatic Aura", "Aegis Protocol", "Judgement", "Strength"]
var PerkListCommando = ["SwapWeapons", "SniperBeam", "WeaponOverCharge"]
var PerkListFleshthing = ["TheEmpress", "TheMoon", "TheSun", "TheStar"]

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
	UnlockPerk()
	UpdateHP()

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

func UnlockPerk():
	var Level = ClassData[CurrentClass]["Level"]
	var FullPerkList = []

	match CurrentClass:
		"Technomancer":
			FullPerkList = PerkListTechnomancer
		"Commando":
			FullPerkList = PerkListCommando
		"Fleshthing":
			FullPerkList = PerkListFleshthing

	var PerksUnlocked = FullPerkList.slice(0, min(Level + 1, FullPerkList.size()))
	ClassData[CurrentClass]["Perks"] = PerksUnlocked
	UpdatePerkList()

func UpdatePerkList():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.UpdatePerkList(ClassData[CurrentClass]["Perks"])

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
