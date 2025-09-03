extends CharacterBody2D

var Class = preload("res://Assets/Scripts/Player Scripts/Classes/Technomancer.gd").new()
var Damage_Timer = Timer.new()

var RecoilEffectResource = preload("res://Assets/Scripts/Effects/Weapon Effects/recoil_effect.gd")

var StartingWeapon = preload("res://Prefabs/CodePrefabs/Weapons/Smg.tscn") # Starting weapon
var CurrentWeapon: Weapon = null # Currently equipped weapon
var ControllerEnabled = false

var IsFiring = false
var CanDodge = true
var IsDodging = false
var IsUsingAbility = false
var AbilityCooldowns = {}
var current_weapon_source := ""

var Invincible = false

var MoveSpeed = 0
var BulletSpeed = 0
var frame_counter := 0

var PlayerUIHandler: Node = null

var icon1: Node = null
var icon2: Node = null
var icon3: Node = null

var owning_entity: Node = null

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
	await get_tree().process_frame
	await get_tree().process_frame
	var ui_list = get_tree().get_nodes_in_group("PlayerUI")
	if ui_list.size() > 0:
		PlayerUIHandler = ui_list[0]
		print("PlayerUIHandler found: ", PlayerUIHandler)
	else:
		print("PlayerUIHandler not found!")
	add_to_group("Player")
	damage_timer()
	
	MoveSpeed = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["MoveSpeed"]
	
	var default_weapon = get_default_weapon_from_swap_upgrade()
	equip_weapon(default_weapon, "SwapWeapons")
	#var penetrate_effect = preload("res://Assets/Scripts/Effects/Projectile Effects/Instances/penetrate_effect.tres")
	#CurrentWeapon.add_effect(penetrate_effect)

	var root = get_tree().get_current_scene()
	if root:
		# Adjust path according to your actual scene hierarchy!
		icon1 = root.get_node("PlayerUI/AbilitiesUI/Icon1")
		icon2 = root.get_node("PlayerUI/AbilitiesUI/Icon2")
		icon3 = root.get_node("PlayerUI/AbilitiesUI/Icon3")

	
func damage_timer():
	Damage_Timer = Timer.new()
	Damage_Timer.wait_time = 1
	Damage_Timer.one_shot = false
	Damage_Timer.connect("timeout", Callable(self, "deal_damage"))
	add_child(Damage_Timer)
	
func _process(delta):
	if Input.is_action_just_pressed("DebugInput"):
		GlobalPlayer.upgrade_weapon("Sniper", 1)
	frame_counter += 1
	update_weapon_rotation()
	if frame_counter >= 30:
		frame_counter = 0
		update_weapon_sprite()

	if IsFiring or (ControllerEnabled and InputEventJoypadMotion):
		attempt_to_fire()
	#if GlobalPlayer.PlayerHP <= 0:
	#	print("DEAD")
	#	GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax
	#	kill()
	
func _physics_process(_delta):
	var Motion = Input.get_vector("left", "right", "up", "down")

	if not IsDodging:
		if Motion.length() > 0:
			if abs(Motion.x) > abs(Motion.y):
				$PlayerSprite.flip_h = Motion.x < 0
				$PlayerSprite/SpriteAnimation.play("WalkRight" if Motion.x > 0 else "WalkLeft")
			else:
				$PlayerSprite/SpriteAnimation.play("WalkDown" if Motion.y > 0 else "WalkUp")
		else:
			#$PlayerSprite/SpriteAnimation.play("Idle")
			pass
			

		if Input.is_action_just_pressed("space") and CanDodge:
			dodge(Motion.normalized())

		velocity = Motion.normalized() * MoveSpeed + velocityknock
	else:
		velocity += velocityknock

	move_and_slide()

	velocityknock = velocityknock.move_toward(Vector2.ZERO, 1000 * _delta)
	
	#var screen_size = get_viewport_rect().size
	#position.x = clamp(position.x, 0, screen_size.x)
	#position.y = clamp(position.y, 0, screen_size.y)
	
func dodge(direction: Vector2):
	if direction == Vector2.ZERO:
		return

	IsDodging = true
	CanDodge = false
	Invincible = true

	var dodge_distance = MoveSpeed * 0.4
	var start_position = global_position
	var dodge_vector = direction.normalized() * dodge_distance
	var end_position = start_position + dodge_vector

	# Temporarily disable collisions
	var collision_shape = $CollisionShape2D
	collision_shape.disabled = true

	# Raycast to prevent clipping into walls
	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(start_position, end_position)
	ray_params.exclude = [self]
	ray_params.collision_mask = 1 << 2  # Environment only
	var ray_result = space_state.intersect_ray(ray_params)
	if ray_result:
		end_position = ray_result.position - direction.normalized() * 4.0

	# Tween movement
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", end_position, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished

	# Re-enable collisions
	collision_shape.disabled = false
	IsDodging = false
	Invincible = false

	# Begin cooldown and update UI
	start_dodge_cooldown(0.5)
	
func start_dodge_cooldown(duration: float):
	if PlayerUIHandler:
		# Start at 0
		PlayerUIHandler.call("UpdateDodgeBar", 0.0)
		
		var tween = get_tree().create_tween()
		tween.tween_method(
			func(ratio):
			PlayerUIHandler.call("UpdateDodgeBar", ratio)
			, 0.0, 1.0, duration)
	else:
		print("No PlayerUIHandler to update dodge bar!")

	await get_tree().create_timer(duration).timeout
	CanDodge = true

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
		print("Checking scene path: ", scene_path)
		if ResourceLoader.exists(scene_path):
			var ability_scene = load(scene_path)
			var ability_instance = ability_scene.instantiate()
			add_child(ability_instance)
			ability_instance.activate(self, index)
			AbilityCooldowns[index] = true
			
			# Start a failsafe timer in case ability doesn't emit signal
			#var failsafe_timer := Timer.new()
			#failsafe_timer.one_shot = true
			#failsafe_timer.wait_time = 1.2 * get_ability_duration_guess(ability_instance) # safe buffer
			#failsafe_timer.timeout.connect(func():
#				if AbilityCooldowns.has(index) and AbilityCooldowns[index]:
#					print("Failsafe triggered for ability", index)
#					_on_ability_cooldown_finished(index)
#			)
#			add_child(failsafe_timer)
#			failsafe_timer.start()

			if ability_instance.has_signal("perk_finished"):
				ability_instance.connect("perk_finished", Callable(self, "_on_ability_cooldown_finished"))
		else:
			print("Could not find ability scene at: " + scene_path)

func _on_ability_cooldown_finished(index: int):
	AbilityCooldowns[index] = false
	print("Ability", index, "is now off cooldown.")
	
func get_ability_duration_guess(ability) -> float: #This entire method is just a failsafe now lmao
	var props = ability.get_property_list()
	for prop in props:
		if prop.name == "Duration":
			return ability.Duration + 1.0
		if prop.name == "CooldownTime":
			return ability.CooldownTime + 1.0
	return 15.0 # Fallback default
	
func _check_for_stuck_cooldowns():
	for index in AbilityCooldowns.keys():
		if AbilityCooldowns[index]:
			print("Warning: Ability", index, "is still on cooldown unexpectedly.")

func equip_weapon(WeaponScene: PackedScene, source: String = ""):
	if CurrentWeapon:
		CurrentWeapon.queue_free()
	
	if WeaponScene:
		CurrentWeapon = WeaponScene.instantiate()
		CurrentWeapon.owning_entity = "Player"
		add_child(CurrentWeapon)
		CurrentWeapon.position = Vector2(0, 0)

		current_weapon_source = source

		if CurrentWeapon.has_signal("shot_fired"):
			CurrentWeapon.connect("shot_fired", Callable(self, "_on_weapon_shot_fired"))
		
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
			
		# Fire the weapon
		CurrentWeapon.attempt_to_fire(global_position, direction)
	
#func eight_directions_snap(direction: Vector2):
	#if direction.length() == 0:
		#return Vector2.ZERO
	#
	#var angle = direction.angle()
	#
	#if angle < 0:
		#angle += 2 * PI # turn negatoves to positives (so the north area works!)
	#
	#var octant_slice = int(round(8 * angle / (2 * PI))) % 8
#
	#match octant_slice:
		#0: return Vector2(1, 0) # Right
		#1: return Vector2(1, 1).normalized() # Bottom Right
		#2: return Vector2(0, 1) # Down
		#3: return Vector2(-1, 1).normalized() # Bottom Left
		#4: return Vector2(-1, 0) # Left
		#5: return Vector2(-1, -1).normalized() # Top Left
		#6: return Vector2(0, -1) # Up
		#7: return Vector2(1, -1).normalized() # Top Right
		#_: return direction.normalized() # Nothing
	
func deal_damage(damage, from_position = null):
	ScreenShake.shake(damage, 0.1)
	GlobalPlayer.PlayerHP -= damage
	
func kill():
	SmearCanvas.reset()
	GlobalAudioController.StopAllMusic()
	
	# Pausing gameplay, death screen and then reset player
	get_tree().paused = true
	var TimeInSeconds = 1.8
	await get_tree().create_timer(TimeInSeconds).timeout
	get_tree().paused = false
	
	get_tree().reload_current_scene()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Invincible:
		return
		
	if body.is_in_group("Enemy") or body.is_in_group("Laser"):
		Damage_Timer.start()

func _on_area_2d_body_exited(body: Node2D) -> void:
	Damage_Timer.stop()


# Janky aSS knockback

var velocityknock = Vector2.ZERO
var knockback_immune = false
var knockback_immunity_time = 0.2

func apply_knockback(force: Vector2) -> void:
	if knockback_immune:
		return

	velocityknock += force
	knockback_immune = true
	await get_tree().create_timer(knockback_immunity_time).timeout
	knockback_immune = false
	
func apply_weapon_knockback(direction: Vector2, force: float) -> void:
	var knockback_vector = -direction.normalized() * force
	apply_knockback(knockback_vector)
	
func _on_weapon_shot_fired(direction: Vector2) -> void:
	var weapon_path = CurrentWeapon.scene_file_path
	if weapon_path == "res://Prefabs/CodePrefabs/Weapons/Shotgun.tscn" or weapon_path == "res://Prefabs/CodePrefabs/Weapons/DragonShotgun.tscn":
		var knockback_force = 200.0 
		apply_weapon_knockback(direction, knockback_force)

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

func start_cooldown_on_slot(slot_index: int, duration: float) -> void:
	print("start_cooldown_on_slot called for slot:", slot_index, "duration:", duration)
	match slot_index:
		1:
			if icon1:
				icon1.start_cooldown(duration)
		2:
			if icon2:
				icon2.start_cooldown(duration)
		3:
			if icon3:
				icon3.start_cooldown(duration)
		_:
			print("Invalid slot index: ", slot_index)

func get_default_weapon_from_swap_upgrade() -> PackedScene:
	var weapon_scenes = WeaponData.weapon_scenes
	var upgrade_slot_1 = GlobalPlayer.weapon_upgrades.get(1, null)

	if upgrade_slot_1 and weapon_scenes.has(upgrade_slot_1):
		return weapon_scenes[upgrade_slot_1]

	return weapon_scenes.get("Smg") # fallback

func is_knockback_weapon(weapon: Weapon) -> bool:
	if weapon == null:
		return false
	
	var weapon_path = weapon.scene_file_path
	if weapon_path == "res://Prefabs/CodePrefabs/Weapons/Shotgun.tscn":
		return true
	if weapon_path == "res://Prefabs/CodePrefabs/Weapons/DragonShotgun.tscn":
		return true
	return false
