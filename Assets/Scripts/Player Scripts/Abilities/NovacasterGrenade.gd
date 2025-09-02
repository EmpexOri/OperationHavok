extends Node2D
class_name NovacasterThrow

signal perk_finished(index: int)
@export var cooldown_time: float = 4.0
var perk_index: int

func activate(player, index = -1):
	perk_index = index
	self.owner = player

	var grenade_scene = preload("res://Prefabs/CodePrefabs/Weapons/NovaGrenade.tscn")
	var grenade = grenade_scene.instantiate()
	get_tree().current_scene.add_child(grenade)

	#var direction = (get_global_mouse_position() - player.global_position).normalized()
	var direction = Vector2()
	
	if player.ControllerEnabled:
		direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
		direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
		if direction.length() > 0.1:
			direction = direction.normalized()
		else:
			return
	else:
		direction = (get_global_mouse_position() - global_position).normalized()
			
	grenade.start(player.global_position, direction)

	_start_cooldown()

func _start_cooldown():
	if owner and owner.has_method("start_cooldown_on_slot"):
		owner.start_cooldown_on_slot(2, cooldown_time)  # slot 2 is grenade
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = cooldown_time
	timer.timeout.connect(_cooldown_complete)
	add_child(timer)
	timer.start()

func _cooldown_complete():
	emit_signal("perk_finished", perk_index)
	queue_free()
