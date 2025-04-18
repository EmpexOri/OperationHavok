extends PanelContainer

@onready var button = $Button
var has_been_pressed = false

func _ready():
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if has_been_pressed:
		return

	# 1. Change panel color
	var new_stylebox = StyleBoxFlat.new()
	new_stylebox.bg_color = Color(1, 0.5, 0.5)  # Light red
	add_theme_stylebox_override("panel", new_stylebox)

	# 2. Replace "SwapWeapons" with "Shotgun" in Commando's Abilities
	var commando_data = GlobalPlayer.ClassData.get("Commando", {})
	if commando_data.has("Abilities"):
		var abilities = commando_data["Abilities"]
		var index = abilities.find("SwapWeapons")
		if index != -1:
			abilities[index] = "Shotgun"
			GlobalPlayer.ClassData["Commando"]["Abilities"] = abilities
			print("Updated Commando Abilities:", abilities)
		else:
			print("SwapWeapons not found in Commando Abilities.")
	else:
		print("No Abilities key found for Commando.")

	# 3. Disable button
	button.disabled = true
	has_been_pressed = true
