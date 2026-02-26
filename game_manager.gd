extends Node2D

var is_season_puzzle_finished = false # وضعیت تمام شدن پازل فصل‌ها
var game_over_scene_path = "res://GameOverScreen.tscn"
var win_screen_scene_path = "res://WinScreen.tscn"
var player_has_time_diamond = false
# این متغیرها وضعیت کلی بازی رو نگه می‌دارن
var current_season = "spring"  # فصل فعلی
var collected_items = []       # لیست آیتم‌های جمع‌آوری شده
var player_score = 2000        # امتیاز بازیکن
var seasons_order = ["spring", "summer", "autumn", "winter"]  # ترتیب فصل‌ها

# این سیگنال‌ها برای ارتباط با UI استفاده می‌شن
signal season_changed(new_season_name)
signal score_updated(new_score)
signal item_collected(item_name)
signal items_updated(items_count)  

func _ready():
	# وقتی بازی شروع می‌شه
	print("GameManager شروع به کار کرد!")
	print("فصل فعلی:", current_season)
	print("امتیاز اولیه:", player_score)
	
	# سیگنال اولیه رو ارسال کن
	emit_signal("season_changed", current_season)
	emit_signal("score_updated", player_score)

# تابع برای تغییر فصل
func change_season(new_season):
	if new_season in seasons_order:
		current_season = new_season
		print("فصل تغییر کرد به:", current_season)
		emit_signal("season_changed", current_season)
		return true
	else:
		print("خطا: فصل نامعتبر:", new_season)
		return false

# تابع برای رفتن به فصل بعد
func go_to_next_season():
	# پیدا کردن ایندکس فصل فعلی
	var current_index = seasons_order.find(current_season)
	
	# اگر فصل آخر نباشیم
	if current_index < seasons_order.size() - 1:
		var next_season = seasons_order[current_index + 1]
		return change_season(next_season)
	else:
		print("این آخرین فصل هست!")
		return false

# تابع برای ثبت آیتم جمع‌آوری شده
func register_item(item_name, item_season):
	print("آیتم ثبت شد:", item_name, " - فصل:", item_season)
	
	if item_season == current_season:
		collected_items.append({"name": item_name, "season": item_season})
		add_score(60)
		
		# سیگنال‌ها رو ارسال کن
		emit_signal("score_updated", player_score)
		emit_signal("items_updated", collected_items.size())  # این خط جدیده
		
		print("آیتم فصل", current_season, "با موفقیت ثبت شد!")
		return true
	else:
		print("خطا! این آیتم مال فصل", item_season, "است!")
		deduct_score(10)
		return false

# تابع برای اضافه کردن امتیاز
func add_score(amount):
	player_score += amount
	print("امتیاز اضافه شد! امتیاز فعلی:", player_score)
	emit_signal("score_updated", player_score)

# تابع برای کم کردن امتیاز
func deduct_score(amount):
	player_score -= amount
	
	# اگر امتیاز منفی شد، صفر کن
	if player_score < 0:
		player_score = 0
	
	print("امتیاز کسر شد! امتیاز فعلی:", player_score)
	emit_signal("score_updated", player_score)
	
	# اگر امتیاز صفر شد، بازی تمومه
	if player_score <= 0:
		show_game_over()

# تابع برای بررسی اینکه آیا بازیکن می‌تونه بره فصل بعد
func can_proceed_to_next_season():
	# باید آیتم فصل فعلی رو جمع کرده باشه
	for item in collected_items:
		if item["season"] == current_season:
			return true
	return false

# تابع برای گرفتن لیست آیتم‌های جمع‌آوری شده برای یه فصل خاص
func get_items_for_season(season):
	var result = []
	for item in collected_items:
		if item["season"] == season:
			result.append(item["name"])
	return result

# تابع برای چاپ وضعیت بازی (برای دیباگ)
func print_game_status():
	print("=== وضعیت بازی ===")
	print("فصل فعلی:", current_season)
	print("امتیاز:", player_score)
	print("آیتم‌های جمع‌آوری شده:", collected_items)
	print("=================")
func change_scene_to_season(season_name):
	# مسیر صحنه فصل مورد نظر
	var scene_path = ""
	
	match season_name:
		"spring":
			scene_path = "res://SpringSeason.tscn"
		"summer":
			scene_path = "res://SummerSeason.tscn"
		"autumn":
			scene_path = "res://AutumnSeason.tscn"
		"winter":
			scene_path = "res://WinterSeason.tscn"
		_:
			print("خطا: صحنه فصل پیدا نشد!")
			return false
	
	print("در حال تغییر به صحنه:", scene_path)
	
	# بارگذاری صحنه
	var next_scene = load(scene_path)
	if next_scene:
		# تغییر صحنه
		get_tree().change_scene_to_packed(next_scene)
		return true
	else:
		print("خطا در بارگذاری صحنه!")
		return false

# تابع برای رفتن به فصل بعد + تغییر صحنه
func go_to_next_season_and_load():
	var current_index = seasons_order.find(current_season)
	if current_index < seasons_order.size() - 1:
		var next_season = seasons_order[current_index + 1]
		# فصل رو در GameManager تغییر بده
		change_season(next_season)
		# صحنه فصل بعد رو بارگذاری کن
		return change_scene_to_season(next_season)
	else:
		is_season_puzzle_finished = true # پازل کامل شد
		print("تمام فصل‌ها تمام شد! بازگشت به ماز اصلی...")
		get_tree().change_scene_to_file("res://MainMaze.tscn") # آدرس صحنه اصلی ماز خود را اینجا بزنید
		return false

func show_game_over():
	print("نمایش صفحه Game Over!")
	
	# صفحه Game Over رو لود کن
	var game_over_scene = load(game_over_scene_path)
	if game_over_scene:
		# به صفحه Game Over برو
		get_tree().change_scene_to_packed(game_over_scene)
	else:
		print("خطا: صفحه Game Over پیدا نشد!")
func show_win_screen():
	print("=== شما برنده شدید! ===")
	print("تبریک! همه فصل‌ها رو تموم کردی!")
	
	# صحنه Win Screen رو لود کن
	var win_scene = load(win_screen_scene_path)
	if win_scene:
		get_tree().change_scene_to_packed(win_scene)
	else:
		print("خطا: صحنه Win Screen پیدا نشد!")
func set_time_diamond_status(has_diamond):
	player_has_time_diamond = has_diamond
	print("GameManager: وضعیت الماس زمان =", player_has_time_diamond)

# تابع برای گرفتن وضعیت الماس زمان
func get_time_diamond_status():
	return player_has_time_diamond

# تابع برای مصرف الماس زمان
func use_time_diamond():
	if player_has_time_diamond:
		player_has_time_diamond = false
		print("GameManager: الماس زمان مصرف شد")
		return true
	return false
