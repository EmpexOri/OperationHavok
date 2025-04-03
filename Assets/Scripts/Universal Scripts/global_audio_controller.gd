extends Node2D

func LevelOneMusic():
	$Level1Soundtrack.play()

func PauseMenuMusic():
	$PauseMenuSoundtrack.play()
	
func DeathSound():
	$DeathSound.play()
	
func ClickSound():
	$ClickSound.play()
