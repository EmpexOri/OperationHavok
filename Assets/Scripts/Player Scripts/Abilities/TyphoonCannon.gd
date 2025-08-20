extends Node2D
class_name TyphoonCannon

signal perk_finished(index: int)

@export var Duration: float = 15.0 # How long the LauncherScene is active for
@export var CooldownTime: float = 10.0 # Cooldown *after* LauncherScene ends

var LauncherScene := preload("res://Prefabs/CodePrefabs/Weapons/TyphoonCannon.tscn")

var PerkIndex: int
var OriginalWeaponScene: PackedScene

var durationTimer: Timer
var cooldownTimer: Timer

var owner_player = null

func activate(player, index = -1):
	print("RocketLauncher: activate() called")
	if not player or not player.CurrentWeapon:
		print("RocketLauncher aborting: no player or no current weapon")
		queue_free()
		return

	PerkIndex = index
	self.owner = player  
	owner_player = player

	var weaponPath = player.CurrentWeapon.scene_file_path
	OriginalWeaponScene = load(weaponPath)

	await get_tree().process_frame
	if is_instance_valid(player) and is_instance_valid(self):  # Safety guard
		player.equip_weapon(LauncherScene, "RocketLauncher")
		print("Swapped to rocket_launcher!")

	# UI cooldown hookup for cooldown time starting NOW (even though actual cooldown starts after duration)
	var icon = get_node_or_null("/root/PlayerUI/AbilitiesUI/Icon3")
	if icon and icon.has_method("start_cooldown"):
		icon.start_cooldown(CooldownTime)

	# Setup duration timer
	durationTimer = Timer.new()
	durationTimer.one_shot = true
	durationTimer.wait_time = Duration
	durationTimer.timeout.connect(_on_duration_timeout)
	add_child(durationTimer)
	durationTimer.start()

	# Start monitoring player's current weapon in process to detect swap away
	set_process(true)

func _process(delta):
	# If player switched weapon before duration ends, start cooldown immediately
	if owner_player and owner_player.CurrentWeapon:
		var current_path = owner_player.CurrentWeapon.scene_file_path
		if current_path != LauncherScene.resource_path:
			print("Player swapped weapon away from RocketLauncher early.")
			_start_cooldown_early()

func _on_duration_timeout():
	# Duration ended normally
	_restore_weapon(owner_player)

func _start_cooldown_early():
	# Stop duration timer if running
	if durationTimer and durationTimer.is_stopped() == false:
		durationTimer.stop()

	# Restore original weapon immediately (if still needed)
	if owner_player and OriginalWeaponScene:
		owner_player.equip_weapon(OriginalWeaponScene, "RocketLauncher")
		print("Restored original weapon due to early swap.")

	# UI cooldown hookup starting NOW, if player has method
	if owner_player and owner_player.has_method("start_cooldown_on_slot"):
		owner_player.start_cooldown_on_slot(3, CooldownTime)  # slot 3 for rocket launcher

	# Start cooldown timer if not already started
	if cooldownTimer == null or cooldownTimer.is_stopped():
		_start_cooldown_timer()
	# Stop monitoring
	set_process(false)

func _restore_weapon(player):
	if player and OriginalWeaponScene and player.current_weapon_source == "RocketLauncher":
		player.equip_weapon(OriginalWeaponScene, "RocketLauncher")
		print("Restored original weapon.")

		if player.has_method("start_cooldown_on_slot"):
			player.start_cooldown_on_slot(3, CooldownTime)  # slot 3 for rocket launcher

	_start_cooldown_timer()
	set_process(false)

func _start_cooldown_timer():
	if cooldownTimer == null:
		cooldownTimer = Timer.new()
		cooldownTimer.one_shot = true
		cooldownTimer.wait_time = CooldownTime
		cooldownTimer.timeout.connect(_cooldown_complete)
		add_child(cooldownTimer)

	if cooldownTimer.is_stopped():
		cooldownTimer.start()
		print("RocketLauncher cooldown started.")

func _cooldown_complete():
	print("RocketLauncher cooldown complete.")
	emit_signal("perk_finished", PerkIndex)
	queue_free()
