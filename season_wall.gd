# اسکریپت متصل به دیوار پازل ۵
extends Node2D # یا هر نوع نودی که هست

func _ready():
	# به محض اینکه ماز لود شد، چک کن ببین پازل قبلاً حل شده؟
	if GameManager.is_season_puzzle_finished:
		print("پازل ۵ قبلاً حل شده، دیوار حذف می‌شود.")
		queue_free() # حذف دیوار از بازی
