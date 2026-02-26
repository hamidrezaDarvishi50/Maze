extends Node2D

# این متغیرها برای UI
@onready var season_label = $UI/InfoPanel/SeasonLabel
@onready var score_label = $UI/InfoPanel/ScoreLabel
@onready var items_label = $UI/InfoPanel/ItemsLabel

@onready var game_manager = get_node("/root/GameManager")

func _ready():
	# وقتی بازی شروع شد
	print("صحنه اصلی بارگذاری شد!")
	
	if game_manager:
		print("GameManager پیدا شد!")
		
		# اول UI رو آپدیت کن
		update_ui()
		
		# به تغییرات GameManager گوش کن
		game_manager.season_changed.connect(_on_season_changed)
		game_manager.score_updated.connect(_on_score_updated)
		game_manager.items_updated.connect(_on_items_updated)
	else:
		print("هشدار: GameManager پیدا نشد!")

# تابع برای آپدیت همه UI
func update_ui():
	update_season_label()
	update_score_label()
	update_items_label()

# تابع برای آپدیت فصل
func update_season_label():
	if game_manager and season_label:
		var season_farsi = ""
		
		# ترجمه فصل به فارسی
		if game_manager.current_season == "spring":
			season_farsi = "بهار"
		elif game_manager.current_season == "summer":
			season_farsi = "تابستان"
		elif game_manager.current_season == "autumn":
			season_farsi = "پاییز"
		elif game_manager.current_season == "winter":
			season_farsi = "زمستان"
		else:
			season_farsi = game_manager.current_season
		
		season_label.text = "فصل: " + season_farsi

# تابع برای آپدیت امتیاز
func update_score_label():
	if game_manager and score_label:
		score_label.text = "امتیاز: " + str(game_manager.player_score)

# تابع برای آپدیت آیتم‌ها
func update_items_label():
	if game_manager and items_label:
		var items_text = "آیتم‌ها: "
		
		# تعداد آیتم‌ها رو نمایش بده
		items_text += str(game_manager.collected_items.size())
		
		# اگر آیتمی جمع شده، اسمش رو هم بنویس
		if game_manager.collected_items.size() > 0:
			items_text += " ("
			for item in game_manager.collected_items:
				# فقط اسم آیتم رو نشون بده
				var item_name = item["name"]
				# کلمات فارسی‌تر
				if "Spring" in item_name:
					items_text += "آب تازه"
				elif "Summer" in item_name:
					items_text += "میوه خشک"
				elif "Autumn" in item_name:
					items_text += "چوب خشک"
				elif "Winter" in item_name:
					items_text += "پشم گرم"
				else:
					items_text += item_name
				
				items_text += ", "
			
			# حذف آخرین ویرگول و فاصله
			items_text = items_text.substr(0, items_text.length() - 2)
			items_text += ")"
		
		items_label.text = items_text

# وقتی فصل تغییر کرد
func _on_season_changed(new_season):
	print("فصل UI تغییر کرد به:", new_season)
	update_season_label()

# وقتی امتیاز تغییر کرد
func _on_score_updated(new_score):
	print("امتیاز UI آپدیت شد:", new_score)
	update_score_label()
func _on_items_updated(items_count):
	print("تعداد آیتم‌ها تغییر کرد:", items_count)
	update_items_label()
