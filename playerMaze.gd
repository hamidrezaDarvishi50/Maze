extends CharacterBody2D

const SPEED = 300.0

# متغیرهای بازیکن
var current_season = "spring"
var game_manager = null
var has_time_diamond = false

# برای محاسبه امتیاز حرکت
var move_counter = 0
var score_deduction_per_move = 10  # طبق قوانین: هر حرکت 10 امتیاز

func _ready():
	# پیدا کردن GameManager
	game_manager = get_node("/root/GameManager")
	
	if game_manager:
		print("Player: GameManager پیدا شد!")
		# فصل رو از GameManager بگیر
		current_season = game_manager.current_season
	else:
		print("Player: هشدار! GameManager پیدا نشد!")



func _physics_process(delta):
	var direction = Vector2.ZERO
	
	# گرفتن ورودی از کیبورد
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	if direction.length() > 0:
		# نرمال‌سازی جهت برای حرکت یکنواخت قطری
		direction = direction.normalized()
		velocity = direction * SPEED
		
		# مدیریت امتیاز (کد هم‌گروهی شما)
		move_counter += 1
		if move_counter >= 10:
			move_counter = 0
			if game_manager:
				game_manager.deduct_score(score_deduction_per_move)
	else:
		velocity = Vector2.ZERO

	# --- این خط بسیار مهم است ---
	move_and_slide()

# تابع جمع‌آوری آیتم
func collect_item(item_name, item_type):
	print("Player: تلاش برای جمع‌آوری آیتم:", item_name)
	
	if game_manager:
		# آیتم رو به GameManager گزارش بده
		var success = game_manager.register_item(item_name, item_type)
		
		if success:
			print("Player: آیتم با موفقیت ثبت شد!")
			# فصل فعلی رو آپدیت کن
			current_season = game_manager.current_season
		else:
			print("Player: مشکلی در ثبت آیتم پیش آمد!")
	else:
		print("Player: GameManager پیدا نشد!")
	
	# برای سازگاری با کد قدیمی
	if item_type == current_season:
		print("Player: آفرین! آیتم فصل", current_season, "رو جمع کردی!")
	else:
		print("Player: این آیتم مال این فصل نیست! فصل فعلی:", current_season)
# تابع جمع‌آوری الماس زمان
func collect_time_diamond():
	print("Player: الماس زمان جمع شد!")
	has_time_diamond = true
	
	# امتیاز اضافه کن (اختیاری)
	if game_manager:
		game_manager.set_time_diamond_status(true)
		game_manager.add_score(100) 
# تابع برای خروج از فصل
# تابع برای خروج از فصل - نسخه جدید
func exit_season():
	print("Player: درخواست خروج از فصل")
	print("Player: وضعیت الماس زمان =", has_time_diamond)
	print("Player: آیتم فصل رو جمع کرده؟ =", game_manager.can_proceed_to_next_season() if game_manager else "GameManager نیست")
	
	if game_manager:
		# اول بررسی کن که آیا آیتم فصل رو جمع کرده یا نه
		var has_season_item = game_manager.can_proceed_to_next_season()
		
		# اگر آیتم فصل رو داره یا الماس زمان داره
		if has_season_item or has_time_diamond:
			print("Player: شرایط خروج فراهم است!")
			
			# اگر با الماس زمان خارج می‌شه
			if not has_season_item and has_time_diamond:
				print("Player: با استفاده از الماس زمان خارج می‌شود")
				has_time_diamond = false  # الماس رو مصرف کن
				if game_manager:
					game_manager.use_time_diamond()
				# به UI اطلاع بده الماس مصرف شد
				if get_parent() and get_parent().has_method("update_diamond_icon"):
					get_parent().update_diamond_icon()
			
			# از GameManager بخواه فصل بعد رو لود کنه
			var success = game_manager.go_to_next_season_and_load()
			
			if success:
				print("Player: صحنه فصل بعد لود شد!")
				current_season = game_manager.current_season
				return true
			else:
				print("Player: خطا در لود کردن صحنه فصل بعد!")
				return false
		else:
			print("Player: نه آیتم این فصل رو داری، نه الماس زمان!")
			return false
	else:
		print("Player: GameManager پیدا نشد!")
		return false
