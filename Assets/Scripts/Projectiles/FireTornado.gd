extends PhysicsProjectile
class_name FireTornado

@export var direction_change_interval: float = 0.75
@export var max_direction_change_angle: float = 45.0
@export var fireout_transition_time: float = 1.0  # seconds before lifetime ends

var _direction_change_timer: float = 0.0
var _has_begun_burning_out: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fireout_timer: Timer = Timer.new()
@onready var damage_area: Area2D = $Area2D  # 👈 reference to your Area2D
@onready var damage_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready():
	super._ready()
	_direction_change_timer = direction_change_interval

	# Add a secondary timer to trigger "fireout"
	add_child(fireout_timer)
	fireout_timer.one_shot = true
	fireout_timer.timeout.connect(_on_fireout_trigger)

	# --- Damage Area Setup ---
	# Make sure it only hits enemies
	damage_area.collision_layer = 1 << 2  # Player projectile
	damage_area.collision_mask = 1 << 1   # Enemy layer
	damage_area.connect("body_entered", Callable(self, "_on_damage_area_body_entered"))

	# Optionally: disable shape until projectile is active
	damage_shape.disabled = false


func start(start_position: Vector2, direction: Vector2, entity_owner: String,
		p_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D,
		damage_multiplier: float):

	super.start(start_position, direction, entity_owner, p_effects, space_state, damage_multiplier)
	self.rotation = 0
	_has_begun_burning_out = false

	# Start the fireout timer so it fires `lifetime - fireout_transition_time` seconds from now
	if lifetime > fireout_transition_time:
		fireout_timer.start(lifetime - fireout_transition_time)


func _handle_movement(delta: float):
	_direction_change_timer -= delta
	if _direction_change_timer <= 0:
		_direction_change_timer = direction_change_interval * randf_range(0.8, 1.2)
		var angle_change = deg_to_rad(randf_range(-max_direction_change_angle, max_direction_change_angle))
		self.velocity = self.velocity.rotated(angle_change).normalized() * speed

	# --- Move the tornado (still using CharacterBody2D motion) ---
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		var reflect_velocity = velocity.bounce(collision_info.get_normal())
		self.velocity = reflect_velocity.rotated(deg_to_rad(randf_range(-15, 15)))


func _on_damage_area_body_entered(body: Node2D) -> void:
	# --- Deal damage when an enemy touches the Area2D ---
	if not is_instance_valid(body):
		return
	if body.has_method("deal_damage"):
		body.deal_damage(damage * current_damage_multiplier, global_position)


# Called when the fireout timer triggers
func _on_fireout_trigger() -> void:
	if _has_begun_burning_out:
		return
	_has_begun_burning_out = true

	var frames: SpriteFrames = anim_sprite.sprite_frames
	if frames and frames.has_animation("fireout"):
		anim_sprite.play("fireout")

		# Stop the normal lifetime timer — we'll clean up after the animation ends
		if not lifetime_timer.is_stopped():
			lifetime_timer.stop()

		anim_sprite.animation_finished.connect(_on_fireout_animation_finished, CONNECT_ONE_SHOT)
	else:
		# no fireout animation: fallback, let lifetime timer handle cleanup
		pass


func _on_fireout_animation_finished() -> void:
	if anim_sprite.animation == "fireout":
		queue_free()
