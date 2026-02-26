extends Node

var score := 2000

func add_score(v:int):
	score += v

func subtract_score(v:int):
	score -= v
	score = max(score, 0)
