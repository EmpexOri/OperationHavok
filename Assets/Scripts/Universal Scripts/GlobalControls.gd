extends Node

# Variables that should persist across scenes

# Player Variables
var PlayerHP: int = 100
var PlayerHPMax: int = 100
var PlayerFP: int = 100
var PlayerFPMax: int = 100
var PlayerDmgMult: float = 1.00

# World Variables
var WorldTimer: float = 0.0
var Score: int = 0

func AddScore(points: int):
	Score += points

func Reset():
	print("Reset function called!")
	PlayerHP = 100
	PlayerHPMax = 100
	PlayerFP = 100
	PlayerFPMax = 100
	WorldTimer = 0.0
	Score = 0
