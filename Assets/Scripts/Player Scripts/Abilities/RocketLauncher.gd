extends Node2D
class_name RocketLauncher

signal perk_finished(index: int)

@export var Duration: float = 10.0 # How long the LauncherScene is active for
@export var CooldownTime: float = 10.0 # Cooldown *after* LauncherScene ends

var LauncherScene := preload("res://Prefabs/CodePrefabs/Weapons/rocket_launcher.tscn")

var PerkIndex: int
var OriginalWeaponScene: PackedScene

func activate(player, index = -1):
	if not player or not player.CurrentWeapon:
		queue_free()
		return

	PerkIndex = index
	self.owner = player  

	# Save the player's current weapon, so we can change things in future :D
	var weaponPath = player.CurrentWeapon.scene_file_path
	OriginalWeaponScene = load(weaponPath)

	# Equip the LauncherScene, so we actually like get it
	player.equip_weapon(LauncherScene, "RocketLauncher")
	print("Swapped to rocket_launcher!")

	# --- UI Cooldown hookup ---
	var icon = get_node_or_null("/root/PlayerUI/AbilitiesUI/Icon3")
	if icon:
		if icon.has_method("start_cooldown"):
			icon.start_cooldown(CooldownTime)
	# --------------------------

	# Start duration timer, this is a bit of a funky one, Godot doesn't like these
	var durationTimer := Timer.new()
	durationTimer.one_shot = true
	durationTimer.wait_time = Duration
	durationTimer.timeout.connect(func():
		_restore_weapon(player)
	)
	add_child(durationTimer)
	durationTimer.start()

func _restore_weapon(player):
	if player and OriginalWeaponScene:
		if player and OriginalWeaponScene and player.current_weapon_source == "RocketLauncher":
			player.equip_weapon(OriginalWeaponScene, "RocketLauncher")
		print("Restored original weapon.")

		# Notify UI cooldown starts NOW, not later
		if player.has_method("start_cooldown_on_slot"):
			player.start_cooldown_on_slot(3, CooldownTime)  # slot 3 for rocket launcher

	# Start cooldown timer for actual cooldown period
	var cooldownTimer := Timer.new()
	cooldownTimer.one_shot = true
	cooldownTimer.wait_time = CooldownTime
	cooldownTimer.timeout.connect(_cooldown_complete)
	add_child(cooldownTimer)
	cooldownTimer.start()

func _cooldown_complete():
	print("RocketLauncher cooldown complete.")
		
	emit_signal("perk_finished", PerkIndex)
	queue_free()
