extends Node

const MAX_SMEARS := 5000
const FADE_TIME := 5.0
const CULL_THRESHOLD := MAX_SMEARS/2
const CULL_FADE_MULTIPLIER := 2.0

var smear_scene := preload("res://Prefabs/Particles/BloodSmear.tscn")
var smear_pool: Array = []
var active_smeares: Array = []

func _process(delta: float) -> void:
	var fade_multiplier := 1.0
	if active_smeares.size() > CULL_THRESHOLD:
		fade_multiplier = CULL_FADE_MULTIPLIER

	for i in range(active_smeares.size() - 1, -1, -1):
		var smear_data = active_smeares[i]
		smear_data.time_left -= delta * fade_multiplier

		var fade_ratio = smear_data.time_left / 15.0  # Adjust to match time_left on spawn
		if is_instance_valid(smear_data.sprite):
			smear_data.sprite.modulate.a = clamp(fade_ratio, 0.0, 1.0)
		else:
			_deactivate_smear(smear_data)
			active_smeares.remove_at(i)
			continue

		if smear_data.time_left <= 0.0 or smear_data.sprite.modulate.a <= 0.0:
			_deactivate_smear(smear_data)
			active_smeares.remove_at(i)

func spawn_smear(position: Vector2) -> void:
	var smear_data = null
	
	# Reuse or instantiate
	if smear_pool.size() > 0:
		smear_data = smear_pool.pop_back()
	else:
		var sprite = smear_scene.instantiate()
		sprite.z_index = -2
		get_tree().current_scene.add_child(sprite)
		smear_data = {
			"sprite": sprite,
			"time_left": 0.0
		}

	smear_data.sprite.global_position = position
	smear_data.sprite.visible = true
	smear_data.sprite.modulate = Color(1, 1, 1, 1)
	smear_data.time_left = 15.0
	active_smeares.append(smear_data)

	if active_smeares.size() > MAX_SMEARS:
		var oldest = active_smeares.pop_front()
		_deactivate_smear(oldest)

func _deactivate_smear(smear_data) -> void:
	var sprite = smear_data.sprite
	if is_instance_valid(sprite):
		sprite.visible = false
		smear_pool.append(smear_data)
