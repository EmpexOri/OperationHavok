extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Fleshthing" # Default class for now

var ClassData = {
	"Technomancer": {"Level": 1, "XP": 0, "MoveSpeed": 200, "BulletSpeed": 1500, "Perks": []},
	"Gunslinger": {"Level": 1, "XP": 0, "MoveSpeed": 300, "BulletSpeed": 2000, "Perks": []},
	"Fleshthing": {"Level": 1, "XP": 0, "MoveSpeed": 150, "BulletSpeed": 500, "Perks": []}
}

# Perk Lists for each class, just place holders for now :D
var PerkListTechnomancer = ["TheEmperor", "TheLovers", "Judgement", "Strength"]
var PerkListGunslinger = ["WheelOfFortune", "Death", "Temperance", "TheHeirophant"]
var PerkListFleshthing = ["TheEmpress", "TheMoon", "TheSun", "TheStar"]

# XP scaling formula
func XPRequiredForLevel(level: int) -> int:
	return 100 * pow(1.2, level - 1)

# Add XP and handle level ups
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

# Level up system
func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	UnlockPerk()  # Unlock a perk when leveling up
	UpdateHP()

# Add hp, used by health pickups, currently scales here
func AddHp(amount: int):
	var level = ClassData[CurrentClass]["Level"]
	var hp_gain_multiplier = 1 + ((level) * 1.5)  
	var adjusted_amount = int(amount * hp_gain_multiplier) 
	PlayerHP = min(PlayerHP + adjusted_amount, PlayerHPMax)
	print(adjusted_amount)
	UpdateHealthBar()

# Update the player's HP based on the class and level
func UpdateHP():
	var level = ClassData[CurrentClass]["Level"]
	if CurrentClass == "Technomancer":
		PlayerHPMax = 100 + min(level, 10) * 25 + max(level - 10, 0) * 10
	elif CurrentClass == "Gunslinger":
		PlayerHPMax = 100 + min(level, 10) * 50 + max(level - 10, 0) * 25
	elif CurrentClass == "Fleshthing":
		PlayerHPMax = 100 + min(level, 10) * 100 + max(level - 10, 0) * 50
	
	PlayerHP += 100
	UpdateHealthBar()

# Unlock perks when a player levels up
func UnlockPerk():
	var level = ClassData[CurrentClass]["Level"]
	var perks_unlocked = []

	# Unlock perks based on the level
	if CurrentClass == "Technomancer":
		perks_unlocked = PerkListTechnomancer.slice(0, level)  # Unlock perks up to current level
	elif CurrentClass == "Gunslinger":
		perks_unlocked = PerkListGunslinger.slice(0, level)
	elif CurrentClass == "Fleshthing":
		perks_unlocked = PerkListFleshthing.slice(0, level)

	# Add the unlocked perks to the class
	ClassData[CurrentClass]["Perks"] = perks_unlocked
	UpdatePerkList()

# Update the UI or system that displays the unlocked perks
func UpdatePerkList():
	var ui_handler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui_handler:
		# Assuming there's a way to display perks, you could update the Perk UI here
		ui_handler.update_perk_list(ClassData[CurrentClass]["Perks"])

# Update XP bar
func UpdateXPBar():
	var level = ClassData[CurrentClass]["Level"]
	var xp_needed = XPRequiredForLevel(level)
	var xp = ClassData[CurrentClass]["XP"]

	var ui_handler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui_handler:
		ui_handler.XPBar.max_value = xp_needed
		ui_handler.XPBar.value = xp

# Update health bar
func UpdateHealthBar():
	var ui_handler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui_handler:
		ui_handler.HealthBar.max_value = PlayerHPMax
		ui_handler.HealthBar.value = PlayerHP
