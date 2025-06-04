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

var MetalCreakSound: AudioStream = preload("res://Assets/Sound/SFX/MetalCreak.mp3")

var paused: bool = false
const MAX_CHANNELS := 5
var DeathChannels: Array[AudioStreamPlayer2D] = []
var GeneralChannels: Array[AudioStreamPlayer2D] = []
#var DeathChannels: Array[AudioStreamPlayer2D] = []

func _ready():
	randomize()
	for i in range(MAX_CHANNELS):
		var path = "SFX/DeathChannelsSFX/Channel%d" % i
		var player = get_node_or_null(path) as AudioStreamPlayer2D
		if player:
			DeathChannels.append(player)
		else:
			push_error("Missing Death channel player node at: %s" % path)
			
	# Setup General SFX Channels
	for i in range(MAX_CHANNELS):
		var path = "SFX/GeneralSFX/Channel%d" % i
		var player = get_node_or_null(path) as AudioStreamPlayer2D
		if player:
			GeneralChannels.append(player)
		else:
			push_error("Missing General SFX channel at: %s" % path)

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
	
func STOPAllMusic():
	var player1 = $Music/Level1Soundtrack
	var player2 = $Music/PauseMenuSoundtrack

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
