extends Node2D
class_name SniperBeam

signal perk_finished(index: int)

@export var cooldown_time: float = 1.0

var smg_scene := preload("res://Prefabs/CodePrefabs/Weapons/Smg.tscn")
var shotgun_scene := preload("res://Prefabs/CodePrefabs/Weapons/beamer.tscn")

var perk_index: int

func activate(player, index = -1):
	perk_index = index

	if not player or not player.CurrentWeapon:
		queue_free()
		return

	var current_weapon_scene = player.CurrentWeapon.scene_file_path

	# Swap logic
	if current_weapon_scene == smg_scene.resource_path:
		player.equip_weapon(shotgun_scene)
		print("Swapped to Shotgun!")
	else:
		player.equip_weapon(smg_scene)
		print("Swapped to SMG!")

	# Start cooldown timer
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
