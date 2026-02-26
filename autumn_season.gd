extends Node2D

# متغیرهای جدید برای UI
@onready var ui = $UI  # اضافه کردن این خط
@onready var season_label = $UI/InfoPanel/SeasonLabel  # تغییر مسیر
@onready var score_label = $UI/InfoPanel/ScoreLabel    # تغییر مسیر
@onready var items_label = $UI/InfoPanel/ItemsLabel    # تغییر مسیر
@onready var diamond_icon = $UI/InfoPanel/DiamondIcon

var item_collected = false
var game_manager = null

func _ready():
	print("فصل پاییز بارگذاری شد!")
	
	# پیدا کردن GameManager
	game_manager = get_node("/root/GameManager")
	var player = get_node_or_null("Player")
	if player and game_manager:
		# وضعیت الماس رو از GameManager بگیر
		player.has_time_diamond = game_manager.get_time_diamond_status()
		print("فصل: وضعیت الماس زمان از GameManager =", player.has_time_diamond)
		update_diamond_icon()

	# اگر UI داریم و GameManager پیدا شد
	if ui and game_manager:
		# UI رو آپدیت کن
		update_ui()
		
		# به تغییرات GameManager گوش کن
		game_manager.season_changed.connect(_on_season_changed)
		game_manager.score_updated.connect(_on_score_updated)
		game_manager.items_updated.connect(_on_items_updated)
	
	# در خروج رو غیرفعال کن
	var exit_door = get_node_or_null("ExitDoor")
	if exit_door:
		exit_door.set_deferred("monitoring", false)

# تابع برای آپدیت UI
func update_ui():
	update_season_label()
	update_score_label()
	update_items_label()
	update_diamond_icon()

func update_season_label():
	if game_manager and season_label:
		var season_farsi = ""
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

func update_score_label():
	if game_manager and score_label:
		score_label.text = "امتیاز: " + str(game_manager.player_score)

func update_items_label():
	if game_manager and items_label:
		var items_text = "آیتم‌ها: "
		
		# تعداد آیتم‌ها رو نمایش بده
		items_text += str(game_manager.collected_items.size())
		
		# اگر آیتمی جمع شده
		if game_manager.collected_items.size() > 0:
			items_text += " ("
			for item in game_manager.collected_items:
				var item_name = item["name"]
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
# تابع برای آپدیت آیکون الماس زمان
func update_diamond_icon():
	if diamond_icon:
		var player = get_node_or_null("Player")
		if player:
			# اگر بازیکن الماس زمان داره، آیکون رو نشون بده
			diamond_icon.visible = player.has_time_diamond
		else:
			diamond_icon.visible = false
# وقتی فصل تغییر کرد
func _on_season_changed(new_season):
	print("فصل تغییر کرد به:", new_season)
	update_season_label()

# وقتی امتیاز تغییر کرد
func _on_score_updated(new_score):
	print("امتیاز آپدیت شد:", new_score)
	update_score_label()

# وقتی آیتم‌ها تغییر کردن
func _on_items_updated(items_count):
	print("تعداد آیتم‌ها:", items_count)
	update_items_label()

# بقیه کدها مثل قبل...
# وقتی آیتم جمع شد
func on_item_collected():
	print("آیتم فصل پاییز جمع شد!")
	item_collected = true
	
	# در خروج رو فعال کن
	var exit_door = get_node_or_null("ExitDoor")
	if exit_door:
		exit_door.set_deferred("monitoring", true)
		
		# رنگ در رو به سبز تغییر بده
		var door_sprite = exit_door.get_node_or_null("Sprite2D")
		if door_sprite:
			door_sprite.modulate = Color.GREEN

# وقتی بازیکن با در برخورد کرد
func _on_exit_door_body_entered(body):
	if body.name == "Player":
		if item_collected:
			print("در خروج فعال است. در حال خروج از فصل پاییز...")
			
			# از بازیکن بخواه از فصل خارج بشه
			var can_exit = body.exit_season()
			
			if can_exit:
				print("خروج موفقیت‌آمیز بود!")
		else:
			print("برای خروج باید اول آیتم رو جمع کنی!")
