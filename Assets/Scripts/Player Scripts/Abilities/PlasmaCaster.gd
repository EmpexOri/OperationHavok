extends Node2D
class_name PlasmaCasterAbility

signal perk_finished(index: int)
@export var cooldown_time: float = 4.0
var perk_index: int

var last_direction: Vector2 = Vector2.RIGHT 

func activate(player, index = -1):
	perk_index = index
	self.owner = player

	var grenade_scene = preload("res://Prefabs/CodePrefabs/Weapons/PlasmaGrenade.tscn")
	var grenade = grenade_scene.instantiate()
	get_tree().current_scene.add_child(grenade)

	var direction = Vector2.ZERO
	
	if player.ControllerEnabled:
		direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
		direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
		
		if direction.length() < 0.01:
			direction = player.last_fire_direction
	else:
		direction = (get_global_mouse_position() - player.global_position).normalized()
			
	grenade.start(player.global_position, direction)

	_start_cooldown()

func _start_cooldown():
	if owner and owner.has_method("start_cooldown_on_slot"):
		owner.start_cooldown_on_slot(2, cooldown_time)  
	
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = cooldown_time
	timer.timeout.connect(_cooldown_complete)
	add_child(timer)
	timer.start()

func _cooldown_complete():
	emit_signal("perk_finished", perk_index)
	queue_free()
