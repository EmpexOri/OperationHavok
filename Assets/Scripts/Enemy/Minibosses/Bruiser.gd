extends Enemy

@onready var sprite = $AnimatedSprite2D
@onready var charge_check_timer: Timer = Timer.new()

var is_ramming = false
var ram_direction = Vector2.ZERO
var is_wandering = true
var wander_offset = Vector2.ZERO
var hit_enemies := {}  # Track which enemies have been hit this ram

# Charge chance logic
var current_charge_chance = 0.1
const CHARGE_CHANCE_INCREMENT = 0.05
const MAX_CHARGE_CHANCE = 0.5
const CHECK_INTERVAL = 1.0
const WALK_SPEED = 80  # normal movement

# RAM / movement constants
const RAM_TRIGGER_DISTANCE = 300
const RAM_BASE_SPEED = 200
const RAM_MAX_SPEED = 400
const RAM_ACCEL_DURATION = 2.0
const RAM_DAMAGE = 50
const ENEMY_RAM_DAMAGE = RAM_DAMAGE * 0.1
const ENEMY_SHOVE_FORCE = 150  # how far the enemy is shoved perpendicular

const MIN_FOLLOW_DISTANCE = 120
const MAX_FOLLOW_DISTANCE = 200
const WANDER_RADIUS = 80  # radius around follow distance to wander

var ram_elapsed = 0.0  # for speed ramping

func start():
	Speed = WALK_SPEED
	Health = 200
	MaxHealth = Health
	Group = "Enemy"
	SummonGroup = "EnemySummon"
	Target = "Player"

func _ready():
	super()
	get_flash_sprite().material = get_flash_sprite().material.duplicate()

	# Charge check timer
	charge_check_timer.one_shot = false
	charge_check_timer.wait_time = CHECK_INTERVAL
	charge_check_timer.connect("timeout", Callable(self, "_attempt_charge"))
	add_child(charge_check_timer)
	charge_check_timer.start()

func _physics_process(_delta):
	var player = resolve_target()
	if not player:
		velocity = Vector2.ZERO
		sprite.stop()
		return

	if is_ramming:
		# Smooth speed ramp
		ram_elapsed += _delta
		var ramp_factor = clamp(ram_elapsed / RAM_ACCEL_DURATION, 0, 1)
		var current_speed = lerp(RAM_BASE_SPEED, RAM_MAX_SPEED, ramp_factor)
		velocity = ram_direction * current_speed

		if sprite.animation != "move":
			sprite.play("move")

		# Move and check collisions
		var collision = move_and_collide(velocity * _delta)
		if collision:
			var collider = collision.get_collider()
			if collider.is_in_group("Enemy") and collider != self:
				if not hit_enemies.has(collider):
					# Shove enemy perpendicular
					var perp = Vector2(-ram_direction.y, ram_direction.x)
					if randi() % 2 == 0:
						perp = -perp
					if "global_position" in collider:
						collider.global_position += perp * ENEMY_SHOVE_FORCE * _delta
					if "deal_damage" in collider:
						collider.deal_damage(ENEMY_RAM_DAMAGE)
					hit_enemies[collider] = true  # mark as hit
				# Do NOT stop ram for already-hit enemies
			else:
				# Stop ram if hitting wall or obstacle
				_on_ram_timeout()
		return

	# Follow player but wander around distance
	is_wandering = true
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var target_distance = clamp(distance, MIN_FOLLOW_DISTANCE, MAX_FOLLOW_DISTANCE)

	# Random offset wandering around player
	if wander_offset == Vector2.ZERO or randf() < 0.02:
		wander_offset = Vector2(randf_range(-WANDER_RADIUS, WANDER_RADIUS), randf_range(-WANDER_RADIUS, WANDER_RADIUS))

	var desired_pos = player.global_position - to_player.normalized() * target_distance + wander_offset
	var direction = (desired_pos - global_position).normalized()
	velocity = direction * WALK_SPEED

	if velocity.length() > 0:
		if sprite.animation != "move":
			sprite.play("move")
		if abs(velocity.x) > 0.1:
			sprite.flip_h = velocity.x > 0
	else:
		sprite.stop()

	move_and_slide()

func _on_area_2d_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		if is_ramming:
			body.deal_damage(RAM_DAMAGE)
		else:
			body.deal_damage(5)
	elif body.is_in_group("Enemy") and not is_ramming:
		# Do nothing when bumping normally
		pass
	elif body.is_in_group("Bullet") or body.is_in_group("Minion"):
		body.queue_free()
		deal_damage(10)

func _attempt_charge():
	if is_ramming:
		return

	var player = resolve_target()
	if not player:
		return

	if global_position.distance_to(player.global_position) <= RAM_TRIGGER_DISTANCE:
		if randf() <= current_charge_chance:
			# Start ram
			start_ramming(player)
			current_charge_chance = 0.1  # reset after ram
		else:
			current_charge_chance = min(current_charge_chance + CHARGE_CHANCE_INCREMENT, MAX_CHARGE_CHANCE)

func get_flash_sprite() -> CanvasItem:
	return sprite

func start_ramming(player: Node2D):
	is_ramming = true
	is_wandering = false
	ram_direction = (player.global_position - global_position).normalized()
	ram_elapsed = 0.0
	hit_enemies.clear()  # reset hit tracking
	sprite.play("move")

func _on_ram_timeout():
	ScreenShake.shake(randf_range(2.0, 5.0), 0.1)
	is_ramming = false
	is_wandering = true
	ram_elapsed = 0.0
	velocity = Vector2.ZERO
	wander_offset = Vector2.ZERO
	hit_enemies.clear()
	sprite.stop()
