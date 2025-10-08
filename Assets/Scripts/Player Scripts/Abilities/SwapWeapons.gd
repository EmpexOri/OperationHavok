extends Node2D
class_name WeaponSwap

signal perk_finished(index: int)

@export var cooldown_time: float = 1.0

@export var weapon1_scene: PackedScene
@export var weapon2_scene: PackedScene

var weapon_scenes = WeaponData.weapon_scenes
var perk_index: int

func activate(player, index = -1):
	perk_index = index
	self.owner = player  # Save reference for UI updates

	# Pull weapon upgrades from GlobalPlayer
	var upgrade_slot_1 = GlobalPlayer.weapon_upgrades.get(1, null)
	var upgrade_slot_2 = GlobalPlayer.weapon_upgrades.get(2, null)

	if upgrade_slot_1 and weapon_scenes.has(upgrade_slot_1):
		weapon1_scene = weapon_scenes[upgrade_slot_1]
	if upgrade_slot_2 and weapon_scenes.has(upgrade_slot_2):
		weapon2_scene = weapon_scenes[upgrade_slot_2]

	# Fallback to default weapons if not set
	if weapon1_scene == null:
		weapon1_scene = weapon_scenes["Smg"]
	if weapon2_scene == null:
		weapon2_scene = weapon_scenes["Shotgun"]

	if not player or not player.CurrentWeapon:
		queue_free()
		return

	var current_weapon_scene = player.CurrentWeapon.scene_file_path

	if current_weapon_scene == weapon1_scene.resource_path:
		player.equip_weapon(weapon2_scene, "SwapWeapons")
		print("Swapped to weapon 2!")
		_update_icon_sprite(weapon2_scene)
	else:
		player.equip_weapon(weapon1_scene, "SwapWeapons")
		print("Swapped to weapon 1!")
		_update_icon_sprite(weapon1_scene)

	GlobalAudioController.PlayWeaponSwapSound()

	# Start cooldown UI on Icon1 via player helper
	if player.has_method("start_cooldown_on_slot"):
		player.start_cooldown_on_slot(1, cooldown_time)

	var cooldown_timer := Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.timeout.connect(_cooldown_complete)
	add_child(cooldown_timer)
	cooldown_timer.start()

func _cooldown_complete():
	print("Weapon swap cooldown complete.")
	emit_signal("perk_finished", perk_index)
	queue_free()

func _update_icon_sprite(weapon_scene: PackedScene) -> void:
	if not owner:
		return
	if not owner.has_method("update_ability_icon_sprite"):
		return
	owner.update_ability_icon_sprite(1, weapon_scene)  # Slot 1 for WeaponSwap
