extends CharacterBody2D

var Class = preload("res://Assets/Scripts/Player Scripts/Classes/Technomancer.gd").new()
var Damage_Timer = Timer.new()
@onready var PlayerSprite: AnimatedSprite2D = $PlayerSprite

@onready var level_controller := get_tree().get_first_node_in_group("LevelController")
var spawn_points := {}   # e.g. { "carpark": Vector2(100,200) }

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
var BaseSpeed: float = 150
var BulletSpeed = 0
var frame_counter := 0

var PlayerUIHandler: Node = null

var icon1: Node = null
var icon2: Node = null
var icon3: Node = null

var owning_entity: Node = null

#Control Locks & Keys
var LockAllControls := false
var LockMovement := false
var LockShooting := false
var LockAbilities := false
var LockDodging := false

#Look Direction Stuff
@onready var AimLine: Line2D = $AimLine
@onready var AimRay: RayCast2D = $AimRay
var AimDistance: float = 600.0 
var AimOffset: float = 10.0
var aim_hit_position: Vector2 = Vector2.ZERO

#Smoother Shooting
var last_fire_direction := Vector2.RIGHT
var aim_input_strength := 0.0

var weapon_data := {
	"res://Prefabs/CodePrefabs/Weapons/Smg.tscn": {
		"name": "SMG",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/SMG.png"),
		"offset": Vector2(5, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/akimbo_smg.tscn": {
		"name": "SMG",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/SMGAkimbo.png"),
		"offset": Vector2(5, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/Shotgun.tscn": {
		"name": "Shotgun",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/Shotgun.png"),
		"offset": Vector2(8, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/DragonShotgun.tscn": {
		"name": "DragonShotgun",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/DragonShotgun.png"),
		"offset": Vector2(8, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/Raygun.tscn": {
		"name": "Raygun",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/Raygun.png"),
		"offset": Vector2(8, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/FlameThrower.tscn": {
		"name": "FlameThrower",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/Flamethrower.png"),
		"offset": Vector2(6, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/M60.tscn": {
		"name": "M60",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/M60.png"),
		"offset": Vector2(6, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/Minigun.tscn": {
		"name": "Minigun",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/Minigun.png"),
		"offset": Vector2(10, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/rocket_launcher.tscn": {
		"name": "RocketLauncher",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/RocketLauncher.png"),
		"offset": Vector2(5, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/RocketMinigun.tscn": {
		"name": "RocketMinigun",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/RocketMinigun.png"),
		"offset": Vector2(5, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/lightning_launcher.tscn": {
		"name": "lightning_launcher",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/LightningGun.png"),
		"offset": Vector2(5, 0)
	},
	"res://Prefabs/CodePrefabs/Weapons/TyphoonCannon.tscn": {
		"name": "TyphoonCannon",
		"sprite": preload("res://Assets/Art/Sprites/Weapons/TyphoonCannon.png"),
		"offset": Vector2(5, 0)
	},
}

@onready var DeathLabel: Label = $"../../PlayerUI/YouDiedLabel"
@onready var DeathBG: ColorRect = $"../../PlayerUI/DeathBG"

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
	
	BaseSpeed = GlobalPlayer.ClassData[GlobalPlayer.CurrentClass]["MoveSpeed"]
	MoveSpeed = BaseSpeed
	
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
	if LockAllControls or LockShooting:
		IsFiring = false
	else:
		if IsFiring or (ControllerEnabled and InputEventJoypadMotion):
			attempt_to_fire()

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
	update_aim_indicator()
	
func _physics_process(delta: float) -> void:
	if LockAllControls or LockMovement:
		# Only allow knockback to move the player
		velocity = velocityknock
		move_and_slide()
		velocityknock = velocityknock.move_toward(Vector2.ZERO, 1000 * delta)
		return
		
	var motion := Input.get_vector("left", "right", "up", "down")
	var motion_normalized := motion.normalized()
	
	velocity = motion_normalized * MoveSpeed + velocityknock
	velocityknock = velocityknock.move_toward(Vector2.ZERO, 1000 * delta)  # decay knockback
	
	move_and_slide()
	
	var fire_dir = _get_fire_direction()
	if fire_dir != Vector2.ZERO:
		AimRay.position = Vector2.ZERO
		AimRay.target_position = fire_dir.normalized() * AimDistance
		AimRay.force_raycast_update()
		
		if AimRay.is_colliding():
			aim_hit_position = AimRay.get_collision_point() - global_position
		else:
			aim_hit_position = fire_dir.normalized() * AimDistance
	else:
		aim_hit_position = Vector2.ZERO
	
	_update_movement_and_fire_animation(motion, fire_dir)
	
	#var screen_size = get_viewport_rect().size
	#position.x = clamp(position.x, 0, screen_size.x)
	#position.y = clamp(position.y, 0, screen_size.y)
	
func _update_movement_animation(motion: Vector2, fire_direction: Vector2 = Vector2.ZERO) -> void:
	if motion.length() == 0:
		PlayerSprite.stop()
		return

	var move_dir := motion.normalized()
	var is_backwards := false

	if fire_direction != Vector2.ZERO:
		var dot := move_dir.dot(fire_direction.normalized())
		if dot < -0.5:  # only invert if clearly opposite
			is_backwards = true
			move_dir = -move_dir

	var angle := move_dir.angle()

	# eight-direction movement
	if angle > -PI/8 and angle <= PI/8:
		PlayerSprite.flip_h = false
		PlayerSprite.play("Walk_Right")
	elif angle > PI/8 and angle <= 3*PI/8:
		PlayerSprite.flip_h = false
		PlayerSprite.play("Walk_DownRight")
	elif angle > 3*PI/8 and angle <= 5*PI/8:
		PlayerSprite.flip_h = false
		PlayerSprite.play("Walk_Down")
	elif angle > 5*PI/8 and angle <= 7*PI/8:
		PlayerSprite.flip_h = true
		PlayerSprite.play("Walk_DownRight")  # flipped for left
	elif angle > 7*PI/8 or angle <= -7*PI/8:
		PlayerSprite.flip_h = true
		PlayerSprite.play("Walk_Right")       # flipped for left
	elif angle > -7*PI/8 and angle <= -5*PI/8:
		PlayerSprite.flip_h = true
		PlayerSprite.play("Walk_UpRight")     # flipped for left
	elif angle > -5*PI/8 and angle <= -3*PI/8:
		PlayerSprite.flip_h = false
		PlayerSprite.play("Walk_Up")
	else:
		PlayerSprite.flip_h = false
		PlayerSprite.play("Walk_UpRight")
	
func dodge(direction: Vector2):
	if direction == Vector2.ZERO:
		return

	IsDodging = true
	CanDodge = false
	Invincible = true

	var dodge_distance = MoveSpeed * 0.5
	var start_position = global_position
	var dodge_vector = direction.normalized() * dodge_distance
	var end_position = start_position + dodge_vector

	# Temporarily disable collisions with enemies
	var collision_shape = $CollisionShape2D
	collision_shape.disabled = true

	# Raycast to prevent clipping into walls only (exclude enemies)
	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(start_position, end_position)
	ray_params.exclude = [self]  # exclude player
	ray_params.collision_mask = 1 << 2  # only walls layer
	var ray_result = space_state.intersect_ray(ray_params)
	if ray_result:
		end_position = ray_result.position - direction.normalized() * 4.0

	# Tween movement
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", end_position, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Tween spin
	var spin_tween = get_tree().create_tween()
	spin_tween.tween_property(PlayerSprite, "rotation_degrees", PlayerSprite.rotation_degrees + 360, 0.2).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	# Reset sprite rotation
	PlayerSprite.rotation_degrees = 0

	# Re-enable collisions
	collision_shape.disabled = false
	IsDodging = false
	Invincible = false

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
	if LockAllControls or LockAbilities:
		return
	
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
		CurrentWeapon = null

	if WeaponScene:
		CurrentWeapon = WeaponScene.instantiate()
		CurrentWeapon.owning_entity = "Player"

		var info = weapon_data.get(CurrentWeapon.scene_file_path)

		if info and info.has("shoulder_weapon") and info.shoulder_weapon:
			# Attach to ShoulderWeapon node
			$ShoulderWeapon.add_child(CurrentWeapon)
			CurrentWeapon.position = info.offset
		else:
			# Attach to normal Weapon node
			$Weapon.add_child(CurrentWeapon)
			CurrentWeapon.position = info.offset

		current_weapon_source = source

		if CurrentWeapon.has_signal("shot_fired"):
			CurrentWeapon.connect("shot_fired", Callable(self, "_on_weapon_shot_fired"))
			
func _get_fire_direction() -> Vector2:
	# Return the direction the player is firing in
	if not CurrentWeapon:
		return Vector2.ZERO
		
	if ControllerEnabled:
		var raw_dir := Vector2(
			Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left"),
			Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
		)
		
		aim_input_strength = raw_dir.length()
		
		if aim_input_strength < 0.15: #some dead zone stuff cause Godot's one is shoddy
			return Vector2.ZERO 
			
		var smoothed = last_fire_direction.lerp(raw_dir.normalized(), 0.25)
		last_fire_direction = smoothed
		return smoothed.normalized()
	else:
		var mouse_dir = get_global_mouse_position() - global_position
		if mouse_dir.length() <= 0.1:
			return Vector2.ZERO
		last_fire_direction = mouse_dir.normalized()
		return last_fire_direction

		
func attempt_to_fire() -> void:
	if not CurrentWeapon:
		return

	var direction := _get_fire_direction()
	if direction == Vector2.ZERO:
		return

	# Only shoot—animation handled in _physics_process
	CurrentWeapon.attempt_to_fire(global_position, direction)
	
func _update_movement_and_fire_animation(motion: Vector2, fire: Vector2) -> void:
	var has_motion := motion.length() > 0
	var has_fire := fire.length() > 0

	# Decide facing direction
	var face_dir := fire if has_fire else motion
	if face_dir.length() == 0:
		# Nothing to face—stay on the last frame and don’t play anything
		PlayerSprite.stop()
		return

	# If moving, play walk; if not moving, play idle
	if has_motion:
		var move_dir := motion
		var is_backwards := false
		if has_fire:
			var dot := move_dir.normalized().dot(face_dir.normalized())
			if dot < -0.5:
				is_backwards = true
				move_dir = -move_dir
		_set_facing_by_vector(face_dir)
		_play_walk_8dir(move_dir, is_backwards)
	else:
		_set_facing_by_vector(face_dir)
		_play_idle_8dir(face_dir)
		
func _set_facing_by_vector(dir: Vector2) -> void:
	if dir.length() == 0:
		return
	PlayerSprite.flip_h = dir.x < 0

func _play_walk_8dir(dir: Vector2, is_backwards: bool) -> void:
	var angle := dir.angle()
	var anim: String = ""
	var flip: bool = false

	if angle > -PI/8 and angle <= PI/8:
		anim = "Walk_Right"
		flip = false
	elif angle > PI/8 and angle <= 3*PI/8:
		anim = "Walk_DownRight"
		flip = false
	elif angle > 3*PI/8 and angle <= 5*PI/8:
		anim = "Walk_Down"
		flip = false
	elif angle > 5*PI/8 and angle <= 7*PI/8:
		anim = "Walk_DownRight"
		flip = true   # mirrored for left
	elif angle > 7*PI/8 or angle <= -7*PI/8:
		anim = "Walk_Right"
		flip = true   # mirrored for left
	elif angle > -7*PI/8 and angle <= -5*PI/8:
		anim = "Walk_UpRight"
		flip = true   # mirrored for left
	elif angle > -5*PI/8 and angle <= -3*PI/8:
		anim = "Walk_Up"
		flip = false
	else: # -3*PI/8 to -PI/8
		anim = "Walk_UpRight"
		flip = false

	# invert if moving backwards
	if is_backwards:
		flip = not flip

	PlayerSprite.flip_h = flip
	PlayerSprite.play(anim)
	
func _play_idle_8dir(dir: Vector2) -> void:
	var angle := dir.angle()
	var anim: String = ""
	var flip: bool = false

	if angle > -PI/8 and angle <= PI/8:
		anim = "Walk_Right"
	elif angle > PI/8 and angle <= 3*PI/8:
		anim = "Walk_DownRight"
	elif angle > 3*PI/8 and angle <= 5*PI/8:
		anim = "Walk_Down"
	elif angle > 5*PI/8 and angle <= 7*PI/8:
		anim = "Walk_DownRight"
		flip = true
	elif angle > 7*PI/8 or angle <= -7*PI/8:
		anim = "Walk_Right"
		flip = true
	elif angle > -7*PI/8 and angle <= -5*PI/8:
		anim = "Walk_UpRight"
		flip = true
	elif angle > -5*PI/8 and angle <= -3*PI/8:
		anim = "Walk_Up"
	else:
		anim = "Walk_UpRight"

	PlayerSprite.flip_h = flip
	PlayerSprite.play(anim)
	PlayerSprite.frame = 0
	PlayerSprite.stop()
	
func deal_damage(damage, from_position = null):
	if Invincible:
		return  # Skip if already invincible
		
	# Apply damage
	ScreenShake.shake(damage, 0.1)
	GlobalPlayer.PlayerHP -= damage
	
	# Flash screen red if no perk points, gold if perk points available
	var color = Color.RED
	if PlayerUIHandler:
		PlayerUIHandler.FlashScreen(color)
		
	var UIHandler = get_node_or_null("/root/MainScene/PlayerUIHandler")
	if UIHandler:
		UIHandler.FlashScreen(color)
		
	# Flash player sprite
	flash_white()  
	GlobalAudioController.PlayPlayerDamageSFX()
	
	# Temporary invincibility
	Invincible = true
	var inv_timer = get_tree().create_timer(0.2)
	await inv_timer.timeout
	Invincible = false

func kill():
	SmearCanvas.reset()
	GlobalAudioController.StopAllMusic()
	get_tree().paused = true
	DeathLabel.visible = true
	DeathBG.visible = true
	await get_tree().create_timer(1.8).timeout
	get_tree().paused = false

	if GlobalPlayer.current_respawn_position != Vector2.ZERO:
		global_position = GlobalPlayer.current_respawn_position
		GlobalPlayer.PlayerHP = GlobalPlayer.PlayerHPMax
		DeathLabel.visible = false
		DeathBG.visible = false
	else:
		get_tree().reload_current_scene()
		
func get_spawn_position(flag:String) -> Vector2:
	if spawn_points.has(flag):
		return spawn_points[flag]
	return Vector2.ZERO  # fallback default

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
	if weapon_path == "res://Prefabs/CodePrefabs/Weapons/RocketMinigun.tscn" or weapon_path == "res://Prefabs/CodePrefabs/Weapons/RocketMinigun.tscn":
		var knockback_force = 100.0 
		apply_weapon_knockback(direction, knockback_force)

func get_current_weapon_info():
	if CurrentWeapon and weapon_data.has(CurrentWeapon.scene_file_path):
		return weapon_data[CurrentWeapon.scene_file_path]
	return null

func update_weapon_sprite():
	if not CurrentWeapon: return
	var info = weapon_data.get(CurrentWeapon.scene_file_path)
	if info:
		var ws = $Weapon/WeaponSprite
		ws.texture = info.sprite
		ws.offset  = info.offset   

func update_weapon_rotation():
	if not CurrentWeapon:
		return
	var direction: Vector2
	if ControllerEnabled:
		direction = _get_fire_direction()
	else:
		direction = (get_global_mouse_position() - global_position)
	if direction == Vector2.ZERO:
		return
	var angle = direction.angle()
	var weapon_sprite = $Weapon/WeaponSprite
	if weapon_sprite:
		if angle > PI / 2 or angle < -PI / 2:
			weapon_sprite.flip_v = true
		else:
			weapon_sprite.flip_v = false
		weapon_sprite.rotation = angle

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

func set_move_speed(value: float):
	MoveSpeed = value

func flash_white(flash_color := Color("cb002e"), times := 1, interval := 0.15):
	if not PlayerSprite:
		return

	# Duplicate material to make it unique
	if PlayerSprite.material:
		PlayerSprite.material = PlayerSprite.material.duplicate()
	else:
		print("PlayerSprite has no material!")

	var mat := PlayerSprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", flash_color)

	var tween := create_tween()
	for i in range(times):
		tween.tween_property(mat, "shader_parameter/flash_strength", 0.5, interval)
		tween.tween_property(mat, "shader_parameter/flash_strength", 0.0, interval)

func register_spawn(flag:String, position:Vector2) -> void:
	spawn_points[flag] = position

func set_master_lock(enabled: bool):
	LockAllControls = enabled
	if enabled:
		IsFiring = false
		IsDodging = false

func lock_movement(enabled: bool):
	LockMovement = enabled

func lock_shooting(enabled: bool):
	LockShooting = enabled
	IsFiring = false

func lock_abilities(enabled: bool):
	LockAbilities = enabled

func lock_dodging(enabled: bool):
	LockDodging = enabled

func update_aim_indicator():
	if not ControllerEnabled or not AimLine:
		AimLine.visible = false
		return

	var dir = _get_fire_direction()
	if dir == Vector2.ZERO:
		AimLine.visible = false
		return

	AimLine.visible = true

	var offset_position = dir.normalized() * AimOffset
	var hit_position = aim_hit_position - offset_position

	AimLine.points = [Vector2.ZERO, hit_position]
	AimLine.position = offset_position

	var alpha = clamp(dir.length() * 2.0, 0.0, 1.0)
	AimLine.modulate.a = alpha
