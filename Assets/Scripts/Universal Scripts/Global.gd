extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Fleshthing" # Default class for now

var ClassData = {
	"Technomancer": {"Level": 1, "XP": 0, "MoveSpeed": 200, "BulletSpeed": 1500},
	"Gunslinger": {"Level": 1, "XP": 0, "MoveSpeed": 300, "BulletSpeed": 2000},
	"Fleshthing": {"Level": 1, "XP": 0, "MoveSpeed": 150, "BulletSpeed": 500}
}

func XPRequiredForLevel(level: int) -> int:
	return 100 * pow(1.2, level - 1)

func AddXP(amount: int):
	var level = ClassData[CurrentClass]["Level"]
	var current_xp = ClassData[CurrentClass]["XP"]
	var xp_needed = XPRequiredForLevel(level)

	current_xp += amount
	while current_xp >= xp_needed:
		current_xp -= xp_needed
		LevelUp()
		xp_needed = XPRequiredForLevel(ClassData[CurrentClass]["Level"])

	ClassData[CurrentClass]["XP"] = current_xp
	UpdateXPBar()

func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	UpdateHP()

func UpdateHP():
	var level = ClassData[CurrentClass]["Level"]
	if CurrentClass == "Technomancer":
		PlayerHPMax = 100 + min(level, 10) * 25 + max(level - 10, 0) * 10
	elif CurrentClass == "Gunslinger":
		PlayerHPMax = 100 + min(level, 10) * 50 + max(level - 10, 0) * 25
	elif CurrentClass == "Fleshthing":
		PlayerHPMax = 100 + min(level, 10) * 100 + max(level - 10, 0) * 50
	
	PlayerHP = PlayerHPMax
	UpdateHealthBar()

func UpdateXPBar():
	var level = ClassData[CurrentClass]["Level"]
	var xp_needed = XPRequiredForLevel(level)
	var xp = ClassData[CurrentClass]["XP"]

	var ui_handler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui_handler:
		ui_handler.XPBar.max_value = xp_needed
		ui_handler.XPBar.value = xp

func UpdateHealthBar():
	var ui_handler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui_handler:
		ui_handler.HealthBar.max_value = PlayerHPMax
		ui_handler.HealthBar.value = PlayerHP
