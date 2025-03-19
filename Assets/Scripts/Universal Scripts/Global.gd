extends Node

# Class-based XP and Level Tracking
var ClassData = {
	"Technomancer": {"Level": 1, "XP": 0},
	"Gunslinger": {"Level": 1, "XP": 0},
	"Fleshthing": {"Level": 1, "XP": 0}
}

# Active Class
var CurrentClass: String = "Technomancer" # Default class for now, we can sleect later

# Player HP (scales with level)
var PlayerHP: int = 100
var PlayerHPMax: int = 100

# XP Formula - Exponential Growth
func XPRequiredForLevel(Level: int) -> int:
	return int(100 * pow(1.2, Level - 1))  # Semi-Exponential XP requirement

# HP Scaling Function
func CalculateMaxHP(Level: int, ClassName: String) -> int:
	match ClassName:
		"Technomancer":
			return 100 + (min(Level, 10) * 25) + (max(Level - 10, 0) * 10)
		"Gunslinger":
			return 100 + (min(Level, 10) * 50) + (max(Level - 10, 0) * 25)
		"Fleshthing":
			return 100 + (min(Level, 10) * 100) + (max(Level - 10, 0) * 50)
	return 100  # Default fallback

# Add XP and handle Level-Up
func AddXP(Amount: int):
	var ClassInfo = ClassData[CurrentClass]
	ClassInfo["XP"] += Amount
	
	while ClassInfo["XP"] >= XPRequiredForLevel(ClassInfo["Level"]):  
		ClassInfo["XP"] -= XPRequiredForLevel(ClassInfo["Level"])
		ClassInfo["Level"] += 1
		PlayerHPMax = CalculateMaxHP(ClassInfo["Level"], CurrentClass)
		PlayerHP = PlayerHPMax  # Heal fully on level-up
		print(CurrentClass, " leveled up to Level ", ClassInfo["Level"], "! New Max HP: ", PlayerHPMax)

# Change the player's current class
func ChangeClass(NewClass: String):
	if NewClass in ClassData:
		CurrentClass = NewClass
		var ClassInfo = ClassData[NewClass]
		PlayerHPMax = CalculateMaxHP(ClassInfo["Level"], NewClass)
		PlayerHP = PlayerHPMax  # Heal when swapping class
	else:
		print("Invalid class: ", NewClass)
