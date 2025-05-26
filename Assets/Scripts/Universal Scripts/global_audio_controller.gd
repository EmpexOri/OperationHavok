extends Node2D

# Load sounds into memory
var HordlingDeathSounds: Array[AudioStream] = [
	preload("res://Assets/Sound/SFX/DeathSFX/HordlingDeathSFX/HorldingDeath1.wav"),
	preload("res://Assets/Sound/SFX/DeathSFX/HordlingDeathSFX/HorldingDeath2.wav"),
	preload("res://Assets/Sound/SFX/DeathSFX/HordlingDeathSFX/HorldingDeath3.wav")
]

var BiomancerDeathSounds: Array[AudioStream] = [
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch1.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch2.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch3.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch4.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/BiomancerDeathSFX/Crunch5.mp3")
]

var MetalCreakSFX: AudioStream = preload("res://Assets/Sound/SFX/MetalCreak.mp3")

const MAX_CHANNELS := 5
var DeathChannels: Array[AudioStreamPlayer2D] = []
var GeneralSFXChannels: Array[AudioStreamPlayer2D] = []

func _ready():
	randomize()
	for i in range(MAX_CHANNELS):
		# Load Death Channels
		var death_path = "SFX/DeathChannelsSFX/Channel%d" % i
		var death_player = get_node_or_null(death_path) as AudioStreamPlayer2D
		if death_player:
			DeathChannels.append(death_player)
		else:
			push_error("Missing Death channel player node at: %s" % death_path)

		# Load General SFX Channels
		var general_path = "SFX/GeneralSFX/Channel%d" % i
		var general_player = get_node_or_null(general_path) as AudioStreamPlayer2D
		if general_player:
			GeneralSFXChannels.append(general_player)
		else:
			push_error("Missing General SFX channel player node at: %s" % general_path)

# Music Controls
func LevelOneMusic():
	$Music/Level1Soundtrack.play()

func PauseMenuMusic():
	$Music/PauseMenuSoundtrack.play()

func STOPPauseMenuMusic():
	$Music/PauseMenuSoundtrack.stop()

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

# Play the Metal Creak sound
func PlayMetalCreak():
	for player in GeneralSFXChannels:
		if not player.playing:
			player.stream = MetalCreakSFX
			player.play()
			return
	print("All General SFX channels are busy!")
