extends Node2D
class_name GrenadeThrow

signal perk_finished(index: int)
@export var cooldown_time: float = 4.0
var perk_index: int

func activate(player, index = -1):
	perk_index = index

	var grenade_scene = preload("res://Prefabs/CodePrefabs/Weapons/Grenade.tscn")
	var grenade = grenade_scene.instantiate()
	get_tree().current_scene.add_child(grenade)

	var direction = (get_global_mouse_position() - player.global_position).normalized()
	grenade.start(player.global_position, direction)

	_start_cooldown()

func _start_cooldown():
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = cooldown_time
	timer.timeout.connect(_cooldown_complete)
	add_child(timer)
	timer.start()

func _cooldown_complete():
	emit_signal("perk_finished", perk_index)
	queue_free()
