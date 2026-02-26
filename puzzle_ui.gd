extends CanvasLayer

# سیگنال خروجی با ۳ وضعیت:
# 0 = شکست کامل
# 1 = پیروزی کامل (امتیاز کامل)
# 2 = پیروزی با نصف امتیاز (شانس دوم)
signal puzzle_solved(result_code)

@onready var title_label = find_child("TitleLabel", true, false)
@onready var question_label = find_child("QuestionLabel", true, false)
@onready var puzzle_image = find_child("PuzzleImage", true, false)

# کانتینرها برای مدیریت نمایش/عدم نمایش
@onready var options_grid = find_child("OptionsGrid", true, false) # برای پازل ۱
@onready var input_box = find_child("InputBox", true, false)       # برای پازل ۲
@onready var answer_input = find_child("AnswerInput", true, false)

var current_puzzle_type = ""
var attempts = 0
var correct_answer = ""

var p3_scene = preload("res://puzzle_3_murder.tscn")
var p4_scene = preload("res://puzzle_4_wordsearch.tscn")


func _ready():
	# اتصال دکمه‌های گزینه‌ای (A, B, C, D) به صورت کدنویسی برای راحتی شما
	# فرض بر این است که نام دکمه‌ها در ادیتور ButtonA, ButtonB, ... است
	for btn_name in ["ButtonA", "ButtonB", "ButtonC", "ButtonD"]:
		var btn = find_child(btn_name, true, false)
		if btn:
			# اتصال سیگنال با ارسال نام دکمه
			btn.pressed.connect(_on_option_button_pressed.bind(btn_name.right(1))) # حرف آخر (A,B,C,D) را میفرستد
	
	hide()

func open_puzzle(type: String):
	if type == "season_start":
		# به جای باز کردن منو، کلاً صحنه بازی را عوض کن
		get_tree().change_scene_to_file("res://SpringSeason.tscn")
		return 
	
	# بقیه کدهای قبلی برای پازل‌های ۱ تا ۴...
	self.show()
	current_puzzle_type = type
	attempts = 0
	
	# --- مرحله ۱: پاکسازی و مخفی‌سازی همه چیز ---
	# این خطوط باعث می‌شود عکس پازل‌های قبلی (مثل Unboxing) دیگر دیده نشود
	if puzzle_image: puzzle_image.hide()
	if options_grid: options_grid.hide()
	if input_box: input_box.hide()
	if title_label: title_label.text = ""
	if question_label: question_label.text = ""
	
	# پاک کردن پازل‌های ۳ و ۴ اگر از قبل در صحنه باقی مانده باشند
	for child in get_children():
		if child.name.contains("Puzzle3") or child.name.contains("Puzzle4") or child.has_signal("puzzle_finished"):
			child.queue_free()

	# --- مرحله ۲: لود کردن پازل درخواستی ---
	var puzzle_instance: Node = null
	
	match type:
		"unboxing":
			setup_unboxing() # این تابع در دل خود puzzle_image.show() دارد
		"algebra":
			setup_algebra()  # این تابع در دل خود puzzle_image.show() و input_box.show() دارد
		"murder":
			puzzle_instance = p3_scene.instantiate()
		"wordsearch":
			puzzle_instance = p4_scene.instantiate()
			
	# --- مرحله ۳: مدیریت پازل‌های اضافه شده (Dynamic) ---
	if puzzle_instance:
		add_child(puzzle_instance)
		# اتصال به تابع مدیریت نتیجه برای پازل‌های ۳ و ۴
		if puzzle_instance.has_signal("puzzle_finished"):
			puzzle_instance.puzzle_finished.connect(_on_puzzle_finished_new)

func _on_puzzle_finished_new(success: bool):
	if success:
		# فرستادن سیگنال برای Player تا دیوار را حذف کند
		puzzle_solved.emit(1) 
		print("پازل با موفقیت حل شد، بازگشت به ماز...")
	else:
		# فرستادن سیگنال شکست
		puzzle_solved.emit(0)
		print("پازل شکست خورد.")

	# --- بخش حیاتی برای لود مجدد ماز ---
	self.hide() # مخفی کردن کل لایه پازل برای دیدن ماز
	
	# پاکسازی نودهای پازل ۳ یا ۴ که با add_child اضافه شده بودند
	for child in get_children():
		if child.has_signal("puzzle_finished"):
			child.queue_free()

# ==========================================
# 📦 پازل ۱: جعبه‌گشایی (Unboxing)
# مکانیک: تک شانس (One Shot)
# ==========================================
func setup_unboxing():
	title_label.text = "استدلال فضایی: جعبه‌گشایی"
	question_label.text = "با توجه به شکل سه‌بعدی، کدام گسترده (A-D) صحیح است؟"
	
	# لود عکس مربوط به مکعب
	puzzle_image.texture = load("res://assets/puzzles/unboxing.png")
	puzzle_image.show()
	
	options_grid.show() # نمایش دکمه‌های A تا D
	correct_answer = "C" # پاسخ صحیح طبق داکیومنت

func _on_option_button_pressed(selected_option: String):
	if current_puzzle_type != "unboxing": return
	
	if selected_option == correct_answer:
		print("Unboxing: Correct!")
		puzzle_solved.emit(1) # برد کامل
		hide()
	else:
		print("Unboxing: Failed immediately.")
		question_label.text = "❌ اشتباه بود! فرصت تمام شد."
		options_grid.hide() # قفل کردن دکمه‌ها
		await get_tree().create_timer(1.5).timeout
		puzzle_solved.emit(0) # شکست کامل
		hide()

# ==========================================
# 🍎 پازل ۲: جبر مصور (Visual Algebra)
# مکانیک: دو شانس (Second Chance - Half Score)
# ==========================================
func setup_algebra():
	title_label.text = "تشخیص الگو: جبر مصور"
	question_label.text = "پاسخ معادله چهارم را وارد کنید:"
	
	puzzle_image.texture = load("res://assets/puzzles/algebra.png")
	puzzle_image.show()
	
	input_box.show() # نمایش فیلد تایپ و دکمه تایید
	answer_input.text = ""
	correct_answer = "11" # پاسخ صحیح (مثال میوه‌ها)

# این تابع باید به سیگنال pressed دکمه SubmitButton وصل شود
func _on_submit_button_pressed():
	if current_puzzle_type != "algebra": return
	
	var user_text = answer_input.text.strip_edges()
	attempts += 1
	
	if user_text == correct_answer:
		if attempts == 1:
			puzzle_solved.emit(1) # برد در تلاش اول (امتیاز کامل)
		else:
			puzzle_solved.emit(2) # برد در تلاش دوم (نصف امتیاز)
		hide()
	else:
		if attempts == 1:
			question_label.text = "❌ اشتباه! یک شانس دیگر دارید (نصف امتیاز):"
			answer_input.text = ""
		else:
			question_label.text = "❌ شکست کامل! راه باز نشد."
			input_box.hide()
			await get_tree().create_timer(1.5).timeout
			puzzle_solved.emit(0) # شکست کامل
			hide()
