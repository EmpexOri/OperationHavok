extends Node2D
class_name Minigun

signal perk_finished(index: int)

@export var Duration: float = 10.0 # How long the Minigun is active for
@export var CooldownTime: float = 10.0 # Cooldown *after* Minigun ends

var MinigunScene := preload("res://Prefabs/CodePrefabs/Weapons/Minigun.tscn")

var PerkIndex: int
var OriginalWeaponScene: PackedScene

func activate(player, index = -1):
	if not player or not player.CurrentWeapon:
		queue_free()
		return

	PerkIndex = index

	# Save the player's current weapon, so we can change things in future :D
	var weaponPath = player.CurrentWeapon.scene_file_path
	OriginalWeaponScene = load(weaponPath)

	# Equip the Minigun, so we actually like get it
	player.equip_weapon(MinigunScene)
	print("Swapped to Minigun!")

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
		player.equip_weapon(OriginalWeaponScene)
		print("Restored original weapon.")

	# After restoring, start the cooldown timer, like SwapWeapons :D
	var cooldownTimer := Timer.new()
	cooldownTimer.one_shot = true
	cooldownTimer.wait_time = CooldownTime
	cooldownTimer.timeout.connect(_cooldown_complete)
	add_child(cooldownTimer)
	cooldownTimer.start()

func _cooldown_complete():
	print("Minigun cooldown complete.")
	emit_signal("perk_finished", PerkIndex)
	queue_free()
