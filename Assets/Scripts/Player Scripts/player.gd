extends CharacterBody2D

var Class = preload("res://Assets/Scripts/Player Scripts/Classes/Technomancer.gd").new()
#var Mode = "fire"
var Damage_Timer = Timer.new()

var StartingWeapon = preload("res://Scenes/Weapons/smg.tscn") # Starting weapon
var CurrentWeapon: Weapon = null # Currently equipped weapon
var ControllerEnabled = false

var IsFiring = false
var CanDodge = true
var IsDodging = false
var IsUsingAbility = false
var PerkCooldowns = {}

var Invincible = false

# Remove MoveSpeed and BulletSpeed as hardcoded variables
var MoveSpeed = 0
var BulletSpeed = 0

func _ready():
	add_to_group("Player")
	damage_timer()
	
	# Retrieve the class-specific MoveSpeed and BulletSpeed from Global
	MoveSpeed = Global.ClassData[Global.CurrentClass]["MoveSpeed"]
	
	equip_weapon(StartingWeapon) # Equip our starting weapon
	
func damage_timer():
	Damage_Timer = Timer.new()
	Damage_Timer.wait_time = 1
	Damage_Timer.one_shot = false
	Damage_Timer.connect("timeout", Callable(self, "deal_damage"))
	add_child(Damage_Timer)
	
func _process(delta):
	if IsFiring or (ControllerEnabled and InputEventJoypadMotion):
		attempt_to_fire()
	if Global.PlayerHP <= 0:
		print("DEAD")
		# Play a sound upon death
		GlobalAudioController.DeathSound()
		Global.PlayerHP = Global.PlayerHPMax
		kill()
	
func _physics_process(_delta):
	var Motion = Vector2()
	
	if not IsDodging:  # Normal movement
		if Input.is_action_pressed("up"):
			Motion.y -= 1
			$PlayerSprite/SpriteAnimation.play("WalkUp")
		if Input.is_action_pressed("down"):
			Motion.y += 1
			$PlayerSprite/SpriteAnimation.play("WalkDown")
		if Input.is_action_pressed("left"):
			Motion.x -= 1
			$PlayerSprite/SpriteAnimation.play("WalkLeft")
		if Input.is_action_pressed("right"):
			Motion.x += 1
			$PlayerSprite/SpriteAnimation.play("WalkRight")

		if Input.is_action_just_pressed("space") and CanDodge:
			dodge(Motion.normalized())

		Motion = Motion.normalized() * MoveSpeed
	else:
		Motion = velocity
		
	velocity = Motion
	move_and_slide()
	
	var screen_size = get_viewport_rect().size
	position.x = clamp(position.x, 0, screen_size.x)
	position.y = clamp(position.y, 0, screen_size.y)
	
func dodge(Direction: Vector2):
	var Collision = get_node("CollisionShape2D")
	if Direction == Vector2.ZERO:
		return

	IsDodging = true
	CanDodge = false
	Invincible = true

	set_collision_layer_value(1, false)
	Collision.disabled = true
	
	# Calculate dodge destination
	var Dodge_Distance = MoveSpeed * 0.9
	var Dodge_Target = global_position + (Direction * Dodge_Distance)
	# Clamp it
	var Screen_Size = get_viewport_rect().size
	Dodge_Target.x = clamp(Dodge_Target.x, 0, Screen_Size.x)
	Dodge_Target.y = clamp(Dodge_Target.y, 0, Screen_Size.y)

	# Use Tween for smooth movement
	var Inbe_tween = get_tree().create_tween()
	Inbe_tween.tween_property(self, "global_position", Dodge_Target, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await Inbe_tween.finished  # Wait for the tween to finish
	IsDodging = false
	set_collision_layer_value(1, true)
	Collision.disabled = false

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

	# Check if the class has the perk and activate it
	if Input.is_action_just_pressed("ability_1"):
		ActivatePerk(0)
	if Input.is_action_just_pressed("ability_2"):
		ActivatePerk(1)
	if Input.is_action_just_pressed("ability_3"):
		ActivatePerk(2)
	#if Input.is_action_just_pressed("ability_4"):
	#	ActivatePerk(3)

func ActivatePerk(index: int):
	if PerkCooldowns.has(index) and PerkCooldowns[index]:
		print("Perk", index, "is on cooldown.")
		return
		
	var perks = Global.ClassData[Global.CurrentClass]["Perks"]
	if index < perks.size():
		var perk_name = perks[index]
		print("Activating perk: " + perk_name)
		var scene_path = "res://Scenes/Abilities/" + perk_name + ".tscn"
		if ResourceLoader.exists(scene_path):
			var perk_scene = load(scene_path)
			var perk_instance = perk_scene.instantiate()
			add_child(perk_instance)
			perk_instance.activate(self, index)
			PerkCooldowns[index] = true

			if perk_instance.has_signal("perk_finished"):
				perk_instance.connect("perk_finished", Callable(self, "_on_perk_cooldown_finished"))
		else:
			print("Could not find perk scene at: " + scene_path)

func _on_perk_cooldown_finished(index: int):
	PerkCooldowns[index] = false
	print("Perk", index, "is now off cooldown.")

func equip_weapon(WeaponScene: PackedScene):
	if CurrentWeapon:
		CurrentWeapon.queue_free() # Free our current weapon
	
	if WeaponScene:
		CurrentWeapon = WeaponScene.instantiate() # Create new weapon instance
		CurrentWeapon.owning_entity = "Player"
		add_child(CurrentWeapon) # Add our new weapon as a child
		
func attempt_to_fire():
	if CurrentWeapon:
		var direction = Vector2() # Get the direction to fire
		
		if ControllerEnabled:
			direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
			direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
			if direction.length() > 0.1:
				direction = direction.normalized()
			else:
				return
		else:
			direction = (get_global_mouse_position() - global_position).normalized() # Get the direction to fire

		if direction.length() > 0:
			var is_horizontal = abs(direction.x) > abs(direction.y)

			if is_horizontal:
				if direction.x > 0:
					$PlayerSprite/SpriteAnimation.play("WalkRight")
				if direction.x < 0:
					$PlayerSprite/SpriteAnimation.play("WalkLeft")
			else:
				if direction.x > 0:
					$PlayerSprite/SpriteAnimation.play("WalkDown")
				if direction.x < 0:
					$PlayerSprite/SpriteAnimation.play("WalkUp")


			
		CurrentWeapon.attempt_to_fire(global_position, direction) # Call weapons attempt to fire method
	
func deal_damage(damage):
	Global.PlayerHP -= damage
	
func kill():
	get_tree().reload_current_scene()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if Invincible == true:
		return
		
	if body.is_in_group("Enemy") or body.is_in_group("Laser"):
		Damage_Timer.start()

func _on_area_2d_body_exited(body: Node2D) -> void:
	Damage_Timer.stop()
