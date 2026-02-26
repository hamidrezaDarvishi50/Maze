extends CanvasLayer

@onready var score_label = $ScoreLabel

func update_score(score: int, bonus: int):
	score_label.text = "Score: %d\nBonus: %d" % [score, bonus]
