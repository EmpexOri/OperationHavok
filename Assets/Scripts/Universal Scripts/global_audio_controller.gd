extends Node2D

# Load sounds into memory for reuse
var death_sounds: Array[AudioStream] = [
	preload("res://Assets/Sound/SFX/DeathSFX/Crunch1.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/Crunch2.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/Crunch3.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/Crunch4.mp3"),
	preload("res://Assets/Sound/SFX/DeathSFX/Crunch5.mp3"),
]

# Channel pool for simultaneous playback
const MAX_HORDLING_CHANNELS := 5  # You can adjust this number as needed
var hordling_channels: Array[AudioStreamPlayer2D] = []

func _ready():
	# Fill up the channel pool with references to the pre-existing AudioStreamPlayers, Can make dynamic later for flexible sizing
	for i in range(MAX_HORDLING_CHANNELS):
		var player_path = "SFX2/HordlingChannels/Channel%d" % i
		var player = get_node(player_path) as AudioStreamPlayer2D
		if player:
			hordling_channels.append(player)
		else:
			push_error("Missing node at: %s" % player_path)

# Set up functions to play each track when called
func LevelOneMusic():
	$Music/Level1Soundtrack.volume_db = -10
	$Music/Level1Soundtrack.play()

func PauseMenuMusic():
	$Music/PauseMenuSoundtrack.volume_db = -10
	$Music/PauseMenuSoundtrack.play()

func STOPPauseMenuMusic():
	$Music/PauseMenuSoundtrack.stop()

func DeathSound():
	$SFX/DeathSound.play()

func ClickSound():
	$SFX/ClickSound.play()

# Function to play Hordling death sound
func HordlingDeath():
	# Try to find an available channel that is not currently playing
	for player in hordling_channels:
		if not player.playing:
			# Randomly select one of the death sounds
			player.stream = death_sounds[randi() % death_sounds.size()]
			player.play()
			return
	
	# If all channels are busy, print a message
	print("All Hordling channels are busy!")
	
#OLD SFX LOADING
#func HordlingDeath():
	# Create an array of death sounds
#	var death_sounds = [
#		$SFX/HordlingDeath1,
#		$SFX/HordlingDeath2,
#		$SFX/HordlingDeath3
#	]

	# Randomly pick one
#	var index = randi() % death_sounds.size()
#	death_sounds[index].play()
