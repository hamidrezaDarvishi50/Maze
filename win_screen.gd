extends Control

# متغیرها برای UI
@onready var final_score_label = $FinalScoreLabel
@onready var restart_button = $Button  # اگه فقط یه دکمه داری

func _ready():
	# وقتی صفحه بارگذاری شد
	print("صفحه برنده‌شدن بارگذاری شد!")
	
	# امتیاز نهایی رو از GameManager بگیر
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		# امتیاز نهایی رو نشون بده
		final_score_label.text = "امتیاز نهایی: " + str(game_manager.player_score)
		
		# امتیاز بونس رو هم حساب کن (اگه خواستی)
		# طبق قوانین پروژه: امتیاز بونس با ۲۰۰۰ میانگین گرفته می‌شه
		var bonus_score = max(0, game_manager.player_score - 2000)  # امتیاز بالای ۲۰۰۰
		var final_with_bonus = (game_manager.player_score + 2000) / 2  # میانگین با ۲۰۰۰
		
		# می‌تونی اینو هم نشون بدی
		print("امتیاز بونس:", bonus_score)
		print("امتیاز با بونس:", final_with_bonus)
	else:
		print("خطا: GameManager پیدا نشد!")
	
	# دکمه رو وصل کن
	restart_button.pressed.connect(_on_restart_pressed)

# وقتی دکمه کلیک شد
func _on_restart_pressed():
	print("شروع مجدد بازی...")
	
	# به صحنه اصلی برگرد
	get_tree().change_scene_to_file("res://main_game.tscn")
