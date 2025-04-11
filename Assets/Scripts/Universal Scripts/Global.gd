extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando" # Default class for now

var ClassData = {
	"Technomancer": {"Level": 1, "XP": 0, "MoveSpeed": 200, "Perks": []},
	"Commando": {"Level": 1, "XP": 0, "MoveSpeed": 150, "Perks": ["SwapWeapons","SniperBeam"]},
	"Fleshthing": {"Level": 1, "XP": 0, "MoveSpeed": 150, "Perks": []}
}

# Perk Lists for each class, just place holders for now :D
var PerkListTechnomancer = ["Technomatic Aura", "Aegis Protocol", "Judgement", "Strength"]
var PerkListCommando = ["SwapWeapons","SniperBeam"]
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
	#print(adjusted_amount)
	#print(PlayerHP)
	UpdateHealthBar()

# Update the player's HP based on the class and level
func UpdateHP():
	var level = ClassData[CurrentClass]["Level"]
	if CurrentClass == "Technomancer":
		PlayerHPMax = 100 + min(level, 10) * 25 + max(level - 10, 0) * 10
	elif CurrentClass == "Commando":
		PlayerHPMax = 100 + min(level, 10) * 50 + max(level - 10, 0) * 25
	elif CurrentClass == "Fleshthing":
		PlayerHPMax = 100 + min(level, 10) * 100 + max(level - 10, 0) * 50
	
	PlayerHP += 100
	UpdateHealthBar()

# Unlock perks when a player levels up, expand on function later
func UnlockPerk():
	var level = ClassData[CurrentClass]["Level"]
	var perks_unlocked = []

	# Get the full perk list of the current class
	var full_perk_list = []
	if CurrentClass == "Technomancer":
		full_perk_list = PerkListTechnomancer
	elif CurrentClass == "Commando":
		full_perk_list = PerkListCommando
	elif CurrentClass == "Fleshthing":
		full_perk_list = PerkListFleshthing

	# Unlock perks based on level (add perks gradually)
	perks_unlocked = full_perk_list.slice(0, min(level + 1, full_perk_list.size()))

	# Update the class perks
	ClassData[CurrentClass]["Perks"] = perks_unlocked
	UpdatePerkList()

# Update the UI or system that displays the unlocked perks
func UpdatePerkList():
	var ui_handler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if ui_handler:
		# One day there's a way to display perks, you could update the Perk UI here
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
