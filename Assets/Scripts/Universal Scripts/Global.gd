extends Node

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando" # Default is commando class

var ClassData = {
	"Technomancer": {"Level": 1, "XP": 0, "MoveSpeed": 200, "Perks": []},
	"Commando": {"Level": 1, "XP": 0, "MoveSpeed": 150, "Perks": ["SwapWeapons","SniperBeam", "WeaponOverCharge"]},
	"Fleshthing": {"Level": 1, "XP": 0, "MoveSpeed": 150, "Perks": []}
}

# Perk Lists for each class, just place holders for now :D
var PerkListTechnomancer = ["Technomatic Aura", "Aegis Protocol", "Judgement", "Strength"]
var PerkListCommando = ["SwapWeapons", "SniperBeam", "WeaponOverCharge"]
var PerkListFleshthing = ["TheEmpress", "TheMoon", "TheSun", "TheStar"]

# XP scaling formula
func XPRequiredForLevel(Level: int) -> int:
	return 100 * pow(1.2, Level - 1)

# Add XP and handle level ups
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

# Level up system
func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	UnlockPerk()  # Unlock a perk when leveling up
	UpdateHP()

# Add hp, used by health pickups, currently scales here
func AddHp(Amount: int):
	var Level = ClassData[CurrentClass]["Level"]
	var HpGainMultiplier = 1 + ((Level) * 1.5)  
	var AdjustedAmount = int(Amount * HpGainMultiplier) 
	PlayerHP = min(PlayerHP + AdjustedAmount, PlayerHPMax)
	#print(AdjustedAmount)
	#print(PlayerHP)
	UpdateHealthBar()

# Update the player's HP based on the class and level
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

# Unlock perks when a player levels up, expand on function later
func UnlockPerk():
	var Level = ClassData[CurrentClass]["Level"]
	var PerksUnlocked = []

	# Get the full perk list of the current class
	var FullPerkList = []
	if CurrentClass == "Technomancer":
		FullPerkList = PerkListTechnomancer
	elif CurrentClass == "Commando":
		FullPerkList = PerkListCommando
	elif CurrentClass == "Fleshthing":
		FullPerkList = PerkListFleshthing

	# Unlock perks based on level (add perks gradually)
	PerksUnlocked = FullPerkList.slice(0, min(Level + 1, FullPerkList.size()))

	# Update the class perks
	ClassData[CurrentClass]["Perks"] = PerksUnlocked
	UpdatePerkList()

# Update the UI or system that displays the unlocked perks
func UpdatePerkList():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		# One day there's a way to display perks, you could update the Perk UI here
		UIHandler.UpdatePerkList(ClassData[CurrentClass]["Perks"])

# Update XP bar
func UpdateXPBar():
	var Level = ClassData[CurrentClass]["Level"]
	var XPNecessary = XPRequiredForLevel(Level)
	var XP = ClassData[CurrentClass]["XP"]

	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.XPBar.max_value = XPNecessary
		UIHandler.XPBar.value = XP

# Update health bar
func UpdateHealthBar():
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.HealthBar.max_value = PlayerHPMax
		UIHandler.HealthBar.value = PlayerHP
