extends Node

@onready var PauseMenuScene: PackedScene = preload("res://Scenes/Options/PauseMenu.tscn")

var PlayerHP: int = 100
var PlayerHPMax: int = 100
var CurrentClass: String = "Commando"
var HelpXP: int = 0
var total_enemies_killed: int = 0
var Level_Time: float = 0.0
var HasRestartedLevel: bool = false

var current_level_scene_path: String = ""

var leaderboard_file_path := "user://leaderboard.save"
var leaderboard: Array = [] 
var use_persistent_leaderboard := false

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
		"Level": 0, "XP": 0, "PerkPoints": 0, "PerPointsSpent": 0, "MoveSpeed": 150,
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

var current_respawn_position: Vector2 = Vector2.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func XPRequiredForLevel(Level: int) -> int:
	return 50 * pow(1.2, Level - 1)

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
	AddHelpXP(Amount*100)
	UpdateXPBar()
	
func AddHelpXP(amount: int):
	HelpXP += amount
	#print("Added HelpXP, new total:", HelpXP)
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.UpdateScore()

func LevelUp():
	ClassData[CurrentClass]["Level"] += 1
	ClassData[CurrentClass]["PerkPoints"] += 1
	UpdateHP()
	UpdatePerkPointUI()
	
	var UIHandler = get_node_or_null("/root/World/PlayerUI")
	if UIHandler:
		UIHandler.FlashScreen(Color(1.0, 0.85, 0.0), 0.3, 1)
		UIHandler.PlayLevelUpEffect()
		
	var audio = get_node_or_null("/root/GlobalAudioController")
	if audio and audio.has_method("PlayLevelUpSound"):
		audio.PlayLevelUpSound()

func AddHp(Amount: int):
	var Level = ClassData[CurrentClass]["Level"]
	var HpGainMultiplier = 1 
	var AdjustedAmount = int(Amount * HpGainMultiplier)
	print (AdjustedAmount)
	PlayerHP = min(PlayerHP + AdjustedAmount, PlayerHPMax)
	UpdateHealthBar()

func UpdateHP():
	var Level = ClassData[CurrentClass]["Level"]
	var base_hp = 100

	var hp = base_hp + min(Level, 10) * 5

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
	Level_Time += delta
	
	if Input.is_action_just_pressed("DebugInput_1"):
		GiveDebugLevels(5)
	if Input.is_action_just_pressed("DebugInput_2"):
		OpenOptions()
	if Input.is_action_just_pressed("DebugInput_3"):
		_restart_game()
	if Input.is_action_just_pressed("DebugInput_5"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			print("Mouse hidden")
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("Mouse visible")
	if Input.is_action_just_pressed("DebugInput_6"):
		toggle_fullscreen()

# Grants the player levels immediately (for debugging)
func GiveDebugLevels(amount: int):
	for i in range(amount):
		LevelUp()
	print("Debug: Gave ", amount, " levels to ", CurrentClass, 
		". New level: ", ClassData[CurrentClass]["Level"])

func reset_match_counters():
	total_enemies_killed = 0

func set_current_level_scene(scene_path: String) -> void:
	current_level_scene_path = scene_path

func get_current_level_scene() -> String:
	return current_level_scene_path

func restart_level():
	reset_player_to_defaults()  
	reset_scores() 
	GlobalAudioController.ClickSound()
	GlobalAudioController.STOPPauseMenuMusic()
	SmearCanvas.reset()
	
	PlayerHP = PlayerHPMax
	
	if get_tree().paused:
		get_tree().paused = false
		
	# Try to clear runtime objects in the level root
	var level_root = get_tree().get_root().get_child(0)
	if level_root and level_root.has_method("clear_runtime_objects"):
		level_root.clear_runtime_objects()
		print("Cleared runtime objects.")
		
	Level_Time = 0.0
	
	# Reset checkpoint by checking for a LevelManager under the level root
	if level_root:
		var level_controller = level_root.get_node_or_null("LevelManager")
		if level_controller:
			print("Level Manager Found & Cleared")
			level_controller.current_checkpoint = ""
			GlobalPlayer.current_respawn_position = Vector2.ZERO
		else:
			print("Level Manager not found in current root")
	# Reload the current scene
	if current_level_scene_path != "":
		get_tree().change_scene_to_file(current_level_scene_path)

func get_formatted_level_time() -> String:
	var minutes = int(Level_Time) / 60
	var seconds = int(Level_Time) % 60
	return str(minutes) + ":" + str(seconds).pad_zeros(2)

func allow_restart():
	if current_level_scene_path != "":
		HasRestartedLevel = false  
		get_tree().change_scene_to_file(current_level_scene_path)

func OpenOptions():
	var world = get_tree().get_root().get_node_or_null("World")
	if not world:
		print("World node not found — cannot open Options Menu.")
		return
	# Try to find an existing PauseMenu in the scene tree
	var pause_menu = world.get_node_or_null("PauseMenu")
	
	if pause_menu:
		print("PauseMenu found in scene — opening Options.")
		if pause_menu.has_method("_on_options_button_pressed"):
			pause_menu._on_options_button_pressed()
		else:
			print("PauseMenu is missing the _on_options_button_pressed method.")
	else:
		print("PauseMenu not found — instantiating a new one.")
		pause_menu = PauseMenuScene.instantiate()
		pause_menu.name = "PauseMenu"
		world.add_child(pause_menu)
		pause_menu.show_pause_menu()
		if pause_menu.has_method("_on_options_button_pressed"):
			pause_menu._on_options_button_pressed()

func _restart_game():
	get_tree().paused = false
	reset_player_to_defaults()
	reset_scores()
	if Engine.has_singleton("GlobalAudioController"):
		GlobalAudioController.STOPPauseMenuMusic()
	if Engine.has_singleton("SmearCanvas"):
		SmearCanvas.reset()
		
	Level_Time = 0.0
	HasRestartedLevel = true
	
	get_tree().change_scene_to_file("res://Scenes/MenuScene.tscn")

func reset_player_to_defaults():
	# Reset core stats
	PlayerHPMax = 100
	PlayerHP = PlayerHPMax
	Level_Time = 0.0
	total_enemies_killed = 0
	current_respawn_position = Vector2.ZERO
	
	# Reset CurrentClass to default
	CurrentClass = "Commando"
	
	# Reset class-level data
	for cls_name in ClassData.keys():
		if cls_name == "Commando":
			ClassData[cls_name]["Level"] = 0
			ClassData[cls_name]["XP"] = 0
			ClassData[cls_name]["PerkPoints"] = 0
			ClassData[cls_name]["PerPointsSpent"] = 0
			ClassData[cls_name]["Abilities"] = ["SwapWeapons", "GrenadeThrow", "RocketLauncher"]
			ClassData[cls_name]["UnlockedAbilities"] = ["SMG", "Grenade", "Minigun"]
		elif cls_name == "Technomancer":
			ClassData[cls_name]["Level"] = 1
			ClassData[cls_name]["XP"] = 0
			ClassData[cls_name]["PerkPoints"] = 0
			ClassData[cls_name]["PerPointsSpent"] = 0
			ClassData[cls_name]["Abilities"] = []
			ClassData[cls_name]["UnlockedAbilities"] = []
		elif cls_name == "Fleshthing":
			ClassData[cls_name]["Level"] = 1
			ClassData[cls_name]["XP"] = 0
			ClassData[cls_name]["PerkPoints"] = 0
			ClassData[cls_name]["PerPointsSpent"] = 0
			ClassData[cls_name]["Abilities"] = []
			ClassData[cls_name]["UnlockedAbilities"] = []

	# Reset weapon upgrades
	weapon_upgrades = {
		1: "Smg",
		2: "Shotgun"
	}
	
	# Update UI
	UpdateHP()
	UpdateXPBar()
	UpdatePerkPointUI()
	UpdateAbilityList()

func reset_scores():
	HelpXP = 0
	total_enemies_killed = 0
	
	# Update UI if it exists
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.UpdateScore()

func toggle_fullscreen():
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Switched to windowed mode")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("Switched to fullscreen mode")

func load_leaderboard():
	if not use_persistent_leaderboard:
		return
	
	if FileAccess.file_exists(leaderboard_file_path):
		var file = FileAccess.open(leaderboard_file_path, FileAccess.READ)
		if file:
			var data = file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(data)
			if typeof(parsed) == TYPE_ARRAY:
				leaderboard = parsed
			else:
				leaderboard = []
	else:
		leaderboard = []

func save_leaderboard():
	if not use_persistent_leaderboard:
		return
	
	var file = FileAccess.open(leaderboard_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard))
		file.close()

func add_leaderboard_entry(player_name: String, score: int, time: float) -> void:
	if use_persistent_leaderboard:
		load_leaderboard()
		
	player_name = player_name.substr(0, 3).to_upper()
	var entry: Dictionary = {"name": player_name, "score": score, "time": time}
	leaderboard.append(entry)
	
	leaderboard.sort_custom(Callable(self, "_compare_leaderboard"))
	
	if leaderboard.size() > 10:
		leaderboard = leaderboard.slice(0, 10)
		
	if use_persistent_leaderboard:
		save_leaderboard()

func _sort_leaderboard(a, b):
	if a["score"] == b["score"]:
		return a["time"] < b["time"]
	return a["score"] > b["score"]

func get_leaderboard_text() -> String:
	if use_persistent_leaderboard:
		load_leaderboard()
		
	var text := "=== LEADERBOARD ===\n"
	for i in range(leaderboard.size()):
		var e = leaderboard[i]
		text += str(i + 1) + ". " + e["name"] + " - " + str(e["score"]) + " pts (" + get_formatted_time(e["time"]) + ")\n"
	return text

func get_formatted_time(t: float) -> String:
	var minutes = int(t) / 60
	var seconds = int(t) % 60
	return str(minutes) + ":" + str(seconds).pad_zeros(2)
	
func _compare_leaderboard(a: Dictionary, b: Dictionary) -> int:
	# Higher score is better (so put higher score earlier)
	if a["score"] > b["score"]:
		return -1
	elif a["score"] < b["score"]:
		return 1
	else:
		# If scores tie, shorter time is better (put smaller time earlier)
		if a["time"] < b["time"]:
			return -1
		elif a["time"] > b["time"]:
			return 1
		else:
			return 0
