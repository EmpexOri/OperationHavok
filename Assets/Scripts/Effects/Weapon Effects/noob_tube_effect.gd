extends WeaponEffect
class_name NoobTubeEffect

@export var grenade_scene: PackedScene
@export var grenade_interval: int = 3
@export var grenade_throw_force: float = 600.0
@export var spawn_offset: float = 20.0   # distance from muzzle/player to spawn
@export var debug_noobtube: bool = true
var noob_sfx: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/Grenade/NoobTube.mp3")

var shot_counter: int = 0

func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2,
		projectile_effects: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D,
		damage_multiplier: float) -> bool:

	shot_counter += 1

	if shot_counter >= grenade_interval:
		shot_counter = 0

		if grenade_scene:
			var grenade: SuperGrenade = grenade_scene.instantiate()
			if grenade:
				# spawn in the world, not as a child of the weapon
				var world = weapon.get_tree().current_scene
				world.add_child(grenade)

				# offset spawn to avoid colliding with the player
				var offset_pos = spawn_position + direction.normalized() * spawn_offset
				grenade.global_position = offset_pos
				GlobalAudioController.PlayFromPlayerSFX(noob_sfx)

				# set throw strength
				grenade.throw_force = grenade_throw_force
				grenade.start(offset_pos, direction)

				if debug_noobtube:
					print("[NoobTube] Fired grenade at ", offset_pos,
						" dir=", direction,
						" throw_force=", grenade_throw_force,
						" offset=", spawn_offset)
		else:
			push_warning("[NoobTube] grenade_scene not assigned!")

		return true  # suppress bullet

	return false  # normal bullet
