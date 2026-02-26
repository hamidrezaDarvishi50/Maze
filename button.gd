extends Button

func _ready():
	# وقتی دکمه کلیک شد، تابع restart_game رو صدا بزن
	pressed.connect(restart_game)

func restart_game():
	print("دکمه شروع مجدد کلیک شد!")
	# به صحنه اصلی بازی برگرد
	get_tree().change_scene_to_file("res://MainGame.tscn")
