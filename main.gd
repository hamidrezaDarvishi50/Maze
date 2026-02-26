extends Node2D

@onready var grid = $Grid
@onready var ui = $UI

func _ready():
	grid.score_changed.connect(ui.update_score)
	# مقدار اولیه
	ui.update_score(grid.score, grid.bonus_score)
