extends CharacterBody2D

var Class = preload("res://Assets/Scripts/Player Scripts/Classes/Technomancer.gd").new()
var Damage_Timer = Timer.new()

var StartingWeapon = preload("res://Prefabs/CodePrefabs/Weapons/Smg.tscn") # Starting weapon
var CurrentWeapon: Weapon = null # Currently equipped weapon
var ControllerEnabled = false

var IsFiring = false
var CanDodge = true
var IsDodging = false
var IsUsingAbility = false
var AbilityCooldowns = {}

var Invincible = false

var MoveSpeed = 0
var BulletSpeed = 0
var frame_counter := 0

var weapon_data := {
	"res://Prefabs/CodePrefabs/Weapons/Smg.tscn": {
		"name": "SMG",
		"sprite": preload("res://Assets/Art/Sprites/SMG.png"),
	},
	"res://Prefabs/CodePrefabs/Weapons/akimbo_smg.tscn": {
		"name": "SMG",
		"sprite": preload("res://Assets/Art/Sprites/SMGAkimbo.png"),
	},
	"res://Prefabs/CodePrefabs/Weapons/Shotgun.tscn": {
		"name": "Shotgun",
		"sprite": preload("res://Assets/Art/Sprites/Shotgun.png"),
	}
}

func _ready():
	add_to_group("Player")
	damage_timer()
	
	MoveSpeed = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["MoveSpeed"]
	
	equip_weapon(StartingWeapon)
	var penetrate_effect = preload("res://Assets/Scripts/Effects/Projectile Effects/Instances/penetrate_effect.tres")
	CurrentWeapon.add_effect(penetrate_effect)
	
func damage_timer():
	Damage_Timer = Timer.new()
	Damage_Timer.wait_time = 1
	Damage_Timer.one_shot = false
	Damage_Timer.connect("timeout", Callable(self, "deal_damage"))
	add_child(Damage_Timer)
	
func _process(delta):
	frame_counter += 1
	update_weapon_rotation()
	if frame_counter >= 30:
		frame_counter = 0
		update_weapon_sprite()

	if IsFiring or (ControllerEnabled and InputEventJoypadMotion):
		attempt_to_fire()
	if GlobalPlayer.PlayerHP <= 0:
		print("DEAD")
		GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax
		kill()
	
func _physics_process(_delta):
	var Motion = Vector2()
	
	if not IsDodging:
		if Input.is_action_pressed("up"):
			Motion.y -= 1
			$PlayerSprite/SpriteAnimation.play("WalkUp")
		if Input.is_action_pressed("down"):
			Motion.y += 1
			$PlayerSprite/SpriteAnimation.play("WalkDown")
		if Input.is_action_pressed("left"):
			Motion.x -= 1
			$PlayerSprite.flip_h = true
			$PlayerSprite/SpriteAnimation.play("WalkLeft")
		if Input.is_action_pressed("right"):
			Motion.x += 1
			$PlayerSprite.flip_h = false
			$PlayerSprite/SpriteAnimation.play("WalkRight")

		if Input.is_action_just_pressed("space") and CanDodge:
			dodge(Motion.normalized())

		Motion = Motion.normalized() * MoveSpeed
	else:
		Motion = velocity
		
	velocity = Motion
	move_and_slide()
	
	#var screen_size = get_viewport_rect().size
	#position.x = clamp(position.x, 0, screen_size.x)
	#position.y = clamp(position.y, 0, screen_size.y)
	
func dodge(direction: Vector2):
	if direction == Vector2.ZERO:
		return
		
	IsDodging = true
	CanDodge = false
	Invincible = true
	
	var dodge_distance = MoveSpeed * 0.7
	var start_position = global_position
	var dodge_vector = direction.normalized() * dodge_distance
	var end_position = start_position + dodge_vector
	
	# Temporarily disable collisions with enemies
	var collision_shape = $CollisionShape2D
	collision_shape.disabled = true
	
	# Use raycast-style check to find the first collision point along the path
	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(start_position, end_position)
	ray_params.exclude = [self]
	ray_params.collision_mask = 1 << 2  # Environment only (e.g., walls)
	
	var ray_result = space_state.intersect_ray(ray_params)
	if ray_result:
		# Adjust endpoint to stop just before hitting the wall
		end_position = ray_result.position - direction.normalized() * 4.0  # 4px offset for safety
		
	# Tween to final position smoothly
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", end_position, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# Re-enable collision
	collision_shape.disabled = false
	IsDodging = false
	
	# Start cooldown
	await get_tree().create_timer(0.35).timeout
	CanDodge = true
	Invincible = false

func _input(event):
	if IsUsingAbility:
		return
		
	if event is InputEventJoypadMotion:
		ControllerEnabled = true

	if event.is_action_pressed("LMB"):
		IsFiring = true
		ControllerEnabled = false
	if event.is_action_released("LMB"):
		IsFiring = false

	if Input.is_action_just_pressed("ability_1"):
		ActivateAbility(0)
	if Input.is_action_just_pressed("ability_2"):
		ActivateAbility(1)
	if Input.is_action_just_pressed("ability_3"):
		ActivateAbility(2)
	# if Input.is_action_just_pressed("ability_4"):
	# 	ActivateAbility(3)

func ActivateAbility(index: int):
	if AbilityCooldowns.has(index) and AbilityCooldowns[index]:
		print("Ability", index, "is on cooldown.")
		return

	var abilities = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["Abilities"]
	if index < abilities.size():
		var ability_name = abilities[index]
		print("Activating ability: " + ability_name)
		var scene_path = "res://Prefabs/CodePrefabs/Abilities/" + ability_name + ".tscn"
		if ResourceLoader.exists(scene_path):
			var ability_scene = load(scene_path)
			var ability_instance = ability_scene.instantiate()
			add_child(ability_instance)
			ability_instance.activate(self, index)
			AbilityCooldowns[index] = true

			if ability_instance.has_signal("perk_finished"):
				ability_instance.connect("perk_finished", Callable(self, "_on_ability_cooldown_finished"))
		else:
			print("Could not find ability scene at: " + scene_path)

func _on_ability_cooldown_finished(index: int):
	AbilityCooldowns[index] = false
	print("Ability", index, "is now off cooldown.")

func equip_weapon(WeaponScene: PackedScene):
	if CurrentWeapon:
		CurrentWeapon.queue_free()
	
	if WeaponScene:
		CurrentWeapon = WeaponScene.instantiate()
		CurrentWeapon.owning_entity = "Player"
		add_child(CurrentWeapon)
		CurrentWeapon.position = Vector2(0, 0) # or offset relative to player sprite
		
func attempt_to_fire():
	if CurrentWeapon:
		var direction = Vector2()
		
		if ControllerEnabled:
			direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
			direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
			if direction.length() > 0.1:
				direction = direction.normalized()
			else:
				return
		else:
			direction = (get_global_mouse_position() - global_position).normalized()

		if direction.length() > 0:
			var is_horizontal = abs(direction.x) > abs(direction.y)

			if is_horizontal:
				if direction.x > 0:
					$PlayerSprite.flip_h = false
					$PlayerSprite/SpriteAnimation.play("WalkRight")
				if direction.x < 0:
					$PlayerSprite.flip_h = true
					$PlayerSprite/SpriteAnimation.play("WalkLeft")
			else:
				if direction.y > 0:
					$PlayerSprite/SpriteAnimation.play("WalkDown")
				if direction.y < 0:
					$PlayerSprite/SpriteAnimation.play("WalkUp")
			
		CurrentWeapon.attempt_to_fire(global_position, direction)
	
func deal_damage(damage, from_position = null):
	GlobalPlayer.PlayerHP -= damage
	
func kill():
	SmearManager.reset()
	get_tree().reload_current_scene()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Invincible:
		return
		
	if body.is_in_group("Enemy") or body.is_in_group("Laser"):
		Damage_Timer.start()

func _on_area_2d_body_exited(body: Node2D) -> void:
	Damage_Timer.stop()


# Janky aSS knockback
var knockback_immune := false
var knockback_immunity_time := 0.3 # seconds

func apply_knockback(force: Vector2):
	if knockback_immune:
		return

	print("Applying knockback:", force)
	velocity += force
	move_and_slide()
	knockback_immune = true
	await get_tree().create_timer(knockback_immunity_time).timeout
	knockback_immune = false

func get_current_weapon_info():
	if CurrentWeapon and weapon_data.has(CurrentWeapon.scene_file_path):
		return weapon_data[CurrentWeapon.scene_file_path]
	return null

func update_weapon_sprite():
	if not CurrentWeapon:
		return
	
	var weapon_path = CurrentWeapon.scene_file_path
	if weapon_data.has(weapon_path):
		var sprite = weapon_data[weapon_path]["sprite"]
		$Weapon/WeaponSprite.texture = sprite

func update_weapon_rotation():
	if not CurrentWeapon:
		return

	var weapon_path = CurrentWeapon.scene_file_path
	if weapon_data.has(weapon_path):
		var weapon_info = weapon_data[weapon_path]
		var weapon_sprite = $Weapon/WeaponSprite

		if weapon_sprite:
			var direction = (get_global_mouse_position() - global_position).normalized()
			var angle = direction.angle()
			# Check if the mouse is on the left side of the character
			if angle > PI / 2 or angle < -PI / 2:
				# Flip the weapon horizontally when aiming to the left
				weapon_sprite.flip_v = true
			else:
				# Keep the weapon as it is when aiming to the right
				weapon_sprite.flip_v = false
			# Apply the rotation without clamping
			weapon_sprite.rotation = angle
			#print("Setting weapon rotation to:", angle)
