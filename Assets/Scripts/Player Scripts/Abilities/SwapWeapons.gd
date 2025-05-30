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

	# Pull weapon upgrades from GlobalPlayer
	var upgrade_slot_1 = GlobalPlayer.weapon_upgrades.get(1, null)
	var upgrade_slot_2 = GlobalPlayer.weapon_upgrades.get(2, null)

	if upgrade_slot_1 and weapon_scenes.has(upgrade_slot_1):
		weapon1_scene = weapon_scenes[upgrade_slot_1]
	if upgrade_slot_2 and weapon_scenes.has(upgrade_slot_2):
		weapon2_scene = weapon_scenes[upgrade_slot_2]

	# Fallback to default weapons if not set, I wont set it manually btw for saftey
	if weapon1_scene == null:
		weapon1_scene = weapon_scenes["Smg"]
	if weapon2_scene == null:
		weapon2_scene = weapon_scenes["Shotgun"]
		
	if not player or not player.CurrentWeapon:
		queue_free()
		return
		
	var current_weapon_scene = player.CurrentWeapon.scene_file_path
	
	if current_weapon_scene == weapon1_scene.resource_path:
		player.equip_weapon(weapon2_scene)
		print("Swapped to weapon 2!")
	else:
		player.equip_weapon(weapon1_scene)
		print("Swapped to weapon 1!")

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

func apply_weapon_upgrade(weapon_name: String, slot: int) -> void:
	if not weapon_scenes.has(weapon_name):
		print("Invalid weapon name: ", weapon_name)
		return

	var new_scene = weapon_scenes[weapon_name]

	match slot:
		1:
			weapon1_scene = new_scene
			print("Weapon 1 upgraded to ", weapon_name)
		2:
			weapon2_scene = new_scene
			print("Weapon 2 upgraded to ", weapon_name)
		_:
			print("Invalid slot: ", slot)
