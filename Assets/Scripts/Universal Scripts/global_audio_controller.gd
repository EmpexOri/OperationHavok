extends Node2D

const MAX_CHANNELS := 15
const MAX_SUSTAINED_CHANNELS := 1

# ----------------------------
# Sound banks
# ----------------------------
var HordlingDeathSounds: Array[AudioStream] = [
	preload("res://Assets/Sound/SFX/DeathSFX/GoreSFX/BitcrushGib1.wav"),
	preload("res://Assets/Sound/SFX/DeathSFX/GoreSFX/BitcrushGib2.wav"),
	preload("res://Assets/Sound/SFX/DeathSFX/GoreSFX/BitcrushGib3.wav")
]

var BiomancerDeathSounds: Array[AudioStream] = [
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch1.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch2.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch3.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch4.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch5.mp3")
]

var LevelUpSound: AudioStream = preload("res://Assets/Sound/SFX/ReactionSFX/LevelUpDiveBomb.wav")

var PlayerDamageSounds: Array[AudioStream] = [
	preload("res://Assets/Sound/SFX/ReactionSFX/Pain_Light1.wav"),
	preload("res://Assets/Sound/SFX/ReactionSFX/Pain_Light2.wav"),
	preload("res://Assets/Sound/SFX/ReactionSFX/Pain_Light3.wav"),
	preload("res://Assets/Sound/SFX/ReactionSFX/Pain_Light4.wav"),
	preload("res://Assets/Sound/SFX/ReactionSFX/Pain_Light5.wav"),
	preload("res://Assets/Sound/SFX/ReactionSFX/Pain_Light6.wav")
]

var lightning_sfx: AudioStream = preload("res://Assets/Sound/SFX/WeaponSFX/LightningGunSustain.mp3")

var Smg_fire_sfx = preload("res://Assets/Sound/SFX/WeaponSFX/Silencetest1.wav")
var Rocket_fire_sfx = preload("res://Assets/Sound/SFX/WeaponSFX/RocketLauncherShot.mp3")
var Shotgun_fire_sfx = preload("res://Assets/Sound/SFX/WeaponSFX/TrimmedShotty2.mp3")
var M60_fire_sfx = preload("res://Assets/Sound/SFX/WeaponSFX/M60Shot.wav")
var XPPickupSound: AudioStream = preload("res://Assets/Sound/SFX/Blip1.wav")
var MetalCreakSound: AudioStream = preload("res://Assets/Sound/SFX/MetalCreak.mp3")
var GrenadeExplosionSound: AudioStream = preload("res://Assets/Sound/SFX/Explode.wav")

var ShieldPingSound: AudioStream = preload("res://Assets/Sound/SFX/ReactionSFX/EnemyReaction/ShieldPing.wav")
var ShieldBreakSound: AudioStream = preload("res://Assets/Sound/SFX/ReactionSFX/EnemyReaction/ShieldBreak.wav")

# ----------------------------
# SFX Channels
# ----------------------------
var DeathChannels: Array[AudioStreamPlayer] = []
var GeneralChannels: Array[AudioStreamPlayer] = []
var PlayerSFXChannels: Array[AudioStreamPlayer] = []
var WeaponSFXChannels: Array[AudioStreamPlayer] = []
var SustainedWeaponChannels: Array[AudioStreamPlayer] = []

var xp_channel = null
var paused: bool = false

# XP pickup pitch scaling
var xp_pitch_multiplier := 1.0
const XP_PITCH_MAX := 2.0
const XP_PITCH_RISE := 0.1
const XP_PITCH_DECAY_RATE := 0.5 # per second

# Round robin indexes
var player_sfx_index := 0
var weapon_sfx_index := 0
#var DeathChannels: Array[AudioStreamPlayer2D] = []

func _ready():
	xp_channel = $SFX/XPPickupChannel as AudioStreamPlayer
	randomize()

	# Death channels
	for i in range(MAX_CHANNELS):
		var player = get_node_or_null("SFX/DeathChannelsSFX/Channel%d" % i) as AudioStreamPlayer
		if player:
			DeathChannels.append(player)

	# General channels
	for i in range(MAX_CHANNELS):
		var player = get_node_or_null("SFX/GeneralSFX/Channel%d" % i) as AudioStreamPlayer
		if player:
			GeneralChannels.append(player)

	# Player SFX channels
	for i in range(MAX_CHANNELS):
		var player = get_node_or_null("SFX/PlayerSFX/Channel%d" % i) as AudioStreamPlayer
		if player:
			PlayerSFXChannels.append(player)

	# Weapon SFX channels
	for i in range(MAX_CHANNELS):
		var player = get_node_or_null("SFX/WeaponSFX/Channel%d" % i) as AudioStreamPlayer
		if player:
			WeaponSFXChannels.append(player)
			
	# Sustained weapon channels
	for i in range(MAX_SUSTAINED_CHANNELS):
		var player = get_node_or_null("SFX/SustainedWeaponSFX/Channel%d" % i) as AudioStreamPlayer
		if player:
			SustainedWeaponChannels.append(player)
			
	if WeaponSFXChannels.size() == 0:
		push_warning("No WeaponSFX channels found! Add nodes under SFX/WeaponSFX")

func _process(delta: float) -> void:
	if xp_pitch_multiplier > 1.0:
		xp_pitch_multiplier = max(1.0, xp_pitch_multiplier - XP_PITCH_DECAY_RATE * delta)

# Music Controls
func LevelOneMusic():
	if paused:
		$Music/Level1Soundtrack.stream_paused = false
		paused = false
	else:
		$Music/Level1Soundtrack.play()

func PausingLevelOneMusic():
	if $Music/Level1Soundtrack.playing:
		$Music/Level1Soundtrack.stream_paused = true
		paused = true

func STOPPauseMenuMusic():
	$Music/PauseMenuSoundtrack.stop()
	
func MusicFadeOut(player: AudioStreamPlayer, duration: float = 2.0) -> void:
	if not player or not player.playing:
		return

	var start_volume = player.volume_db
	var target_volume = -80.0  # silence

	var tween = create_tween()
	tween.tween_property(player, "volume_db", target_volume, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.connect("finished", Callable(player, "stop"))
	
func STOPAllMusic(): #Kinda Legacy, see new below
	var player1 = $Music/Level1Soundtrack
	var player2 = $Music/PauseMenuSoundtrack
	
func StopAllMusic():
	var music_node = $Music
	for child in music_node.get_children():
		if child is AudioStreamPlayer:
			child.stop()

# UI SFX
func DeathSound():
	$SFX/DeathSound.play()

func ClickSound():
	$SFX/ClickSound.play()

# Play random Hordling death sound
func HordlingDeath():
	for player in DeathChannels:
		if not player.playing:
			player.stream = HordlingDeathSounds[randi() % HordlingDeathSounds.size()]
			
			# Speed up by 20%
			player.pitch_scale = 1.2 * randf_range(0.95, 1.05)  # Base speed up + small random variation
			
			# Add small random start offset (up to 0.1 seconds)
			player.seek(randf_range(0.0, 0.1))
			
			player.play()
			return
	print("All Hordling channels are busy!")

# Play random Biomancer death sound
func BiomancerDeath():
	for player in DeathChannels:
		if not player.playing:
			player.stream = BiomancerDeathSounds[randi() % BiomancerDeathSounds.size()]
			player.play()
			return
	print("All Biomancer channels are busy!")
	
func PlayGrenadeExplosion():
	for player in GeneralChannels:
		if not player.playing:
			player.stream = GrenadeExplosionSound
			player.volume_db = 5
			player.play()
			ScreenShake.shake(randf_range(5.0, 7.0), randf_range(0.1, 0.4))
			return
	print("All General SFX channels are busy!")
	
func SetLevel1Music(song_path: String, play_immediately: bool = true):
	var stream: AudioStream = load(song_path)
	if not stream:
		push_warning("Failed to load Level 1 music: " + song_path)
		return
	
	var player = $Music/Level1Soundtrack
	player.stream = stream
	
	# Reset volume in case it was faded out previously
	player.volume_db = -10

	if play_immediately:
		player.play()
		paused = false
	
func PauseMenuMusic():
	var player = $Music/PauseMenuSoundtrack
	player.stream = load("res://Assets/Sound/Music/MenuMusic.mp3")
	player.play()

func PlayMetalCreak():
	for player in GeneralChannels:
		if not player.playing:
			player.stream = MetalCreakSound
			player.play()
			return
	print("All General SFX channels are busy!")

func PlayMainMenuMusic():
	var player = $Music/MainMenuLoop
	var stream: AudioStream = load("res://Assets/Sound/Music/Luxopolis.mp3")

	if stream is AudioStream:
		var stream_copy = stream.duplicate() as AudioStream
		stream_copy.set_loop(true)
		player.stream = stream_copy

		# Start at silence, we can tween out :D
		player.volume_db = -80
		player.play()

		# Create fade-in tween
		var tween = create_tween()
		tween.tween_property(
			player,
			"volume_db",
			-20,
			3.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func StopMainMenuMusic():
	$Music/MainMenuLoop.stop()

func is_main_menu_music_playing() -> bool:
	return $Music/MainMenuLoop.playing

func PlayXPPickupSound():
	var xp_player := $SFX/XPPickupChannel
	if not xp_player:
		print("Missing XP player")
		return

	if xp_player.playing:
		xp_player.stop()

	xp_player.stream = XPPickupSound
	xp_player.pitch_scale = clamp(xp_pitch_multiplier, 0.5, XP_PITCH_MAX)
	xp_player.play()

	# Increase pitch for next pickup if called rapidly
	xp_pitch_multiplier = min(XP_PITCH_MAX, xp_pitch_multiplier + XP_PITCH_RISE)

# ----------------------------
# Weapon fire helpers
# ----------------------------
func SmgFire():
	for player in WeaponSFXChannels:
		if not player.playing:
			player.stream = Smg_fire_sfx
			player.pitch_scale = randf_range(0.95, 1.05)
			player.volume_db = -8
			player.play()
			return

	# Round-robin if all channels busy
	if WeaponSFXChannels.size() > 0:
		weapon_sfx_index = (weapon_sfx_index + 1) % WeaponSFXChannels.size()
		var player = WeaponSFXChannels[weapon_sfx_index]
		player.stop()
		player.stream = Smg_fire_sfx
		player.pitch_scale = randf_range(0.95, 1.05)
		player.volume_db = -8
		player.play()
	
func RocketFire():
	PlayFromWeaponSFX(Rocket_fire_sfx)
	
func M60Fire():
	PlayFromWeaponSFX(M60_fire_sfx)

func ShotgunFire():
	for player in WeaponSFXChannels:
		if not player.playing:
			player.stream = Shotgun_fire_sfx
			player.pitch_scale = randf_range(0.95, 1.05)
			player.volume_db = -10  # Lower the shotgun volume here
			player.play()
			break

	ScreenShake.shake(randf_range(2.0,3.0), 0.2)
	
func PlayLightningHitSFX():
	PlayFromWeaponSFX(lightning_sfx)
# ----------------------------
# Weapon SFX
# ----------------------------
func PlayFromWeaponSFX(stream: AudioStream) -> void:
	for player in WeaponSFXChannels:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = randf_range(0.95, 1.05)

			# If it's the lightning SFX, make it slightly louder
			if stream == GlobalAudioController.lightning_sfx:
				player.volume_db = 2.5
			else:
				player.volume_db = -15  # normal volume

			player.play()
			return

	# Round-robin overwrite if all channels busy
	if WeaponSFXChannels.size() > 0:
		weapon_sfx_index = (weapon_sfx_index + 1) % WeaponSFXChannels.size()
		var player = WeaponSFXChannels[weapon_sfx_index]
		player.stop()
		player.stream = stream
		player.pitch_scale = randf_range(0.95, 1.05)
		if stream == GlobalAudioController.lightning_sfx:
			player.volume_db = 3.5
		else:
			player.volume_db = 0
		player.play()

func PlayFromPlayerSFX(stream: AudioStream) -> void:
	# Try to find a free channel
	for player in PlayerSFXChannels:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = randf_range(0.95, 1.05)  # Random pitch modulation
			player.play()
			return
	
	# All channels busy, overwrite the next in round-robin order
	if PlayerSFXChannels.size() > 0:
		player_sfx_index = (player_sfx_index + 1) % PlayerSFXChannels.size()
		var player = PlayerSFXChannels[player_sfx_index]
		player.stop()
		player.stream = stream
		player.pitch_scale = randf_range(0.95, 1.05)  # Random pitch modulation
		player.play()
		
func PlayPlayerDamageSFX():
	var sound_to_play = PlayerDamageSounds[randi() % PlayerDamageSounds.size()]
	
	for player in PlayerSFXChannels:
		if not player.playing:
			player.stream = sound_to_play
			player.pitch_scale = randf_range(0.95, 1.05)
			player.play()
			return
	# Round-robin overwrite if all channels are busy
	if PlayerSFXChannels.size() > 0:
		player_sfx_index = (player_sfx_index + 1) % PlayerSFXChannels.size()
		var player = PlayerSFXChannels[player_sfx_index]
		player.stop()
		player.stream = sound_to_play
		player.pitch_scale = randf_range(0.95, 1.05)
		player.play()

func play_general_sfx(sound_path: String) -> void:
	var audio_controller = get_node("/root/GlobalAudioController")  # adjust path if needed
	if not audio_controller:
		push_warning("GlobalAudioController not found")
		return

	var stream: AudioStream = load(sound_path)  # <-- use load() instead of preload()
	if not stream:
		push_warning("Failed to load sound: " + sound_path)
		return

	for player in audio_controller.GeneralChannels:
		if not player.playing:
			player.stream = stream
			player.play()
			return

	# All channels busy, just overwrite a random one
	if audio_controller.GeneralChannels.size() > 0:
		var index = randi() % audio_controller.GeneralChannels.size()
		var player = audio_controller.GeneralChannels[index]
		player.stop()
		player.stream = stream
		player.play()

func PlayLevelUpSound():
	for player in GeneralChannels:
		if not player.playing:
			player.stream = LevelUpSound
			player.volume_db = -10
			player.play()
			return
	# fall-back overwrite if all busy
	if GeneralChannels.size() > 0:
		var p = GeneralChannels[randi() % GeneralChannels.size()]
		p.stop()
		p.stream = LevelUpSound
		p.volume_db = -10
		p.play()

func PlayShieldPing():
	for player in GeneralChannels:
		if not player.playing:
			player.stream = ShieldPingSound
			player.pitch_scale = randf_range(0.8, 1.2)  
			player.volume_db = -6.0 
			player.play()
			return
	if GeneralChannels.size() > 0:
		var p = GeneralChannels[randi() % GeneralChannels.size()]
		p.stop()
		p.stream = ShieldPingSound
		p.pitch_scale = randf_range(0.8, 1.2)
		p.volume_db = -6.0       
		p.play()

func PlayShieldBreak():
	for player in GeneralChannels:
		if not player.playing:
			player.stream = ShieldBreakSound
			player.pitch_scale = 1.0
			player.play()
			return
	if GeneralChannels.size() > 0:
		var p = GeneralChannels[randi() % GeneralChannels.size()]
		p.stop()
		p.stream = ShieldBreakSound
		p.pitch_scale = 1.0
		p.play()
