extends Node

@export var player: NodePath
@onready var game_over_label = $GameOver
@onready var hp_label = $HBoxContainer/HP
@onready var kills_label = $HBoxContainer/Kills

func show_game_over():
	game_over_label.visible = true
	get_tree().paused = true

func update_hp(hp):
	hp_label.text = "HP: %d" % hp
	
func update_kill(kills):
	kills_label.text = "Kills: %d" % kills
