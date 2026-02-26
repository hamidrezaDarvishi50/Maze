extends Node2D

const CELL_SIZE = 64
# شروع از ردیف 4 (وسط سمت چپ) طبق عکس
var grid_pos = Vector2i(0, 4) 

var steps_in_fog = 0
var last_safe_pos = Vector2i.ZERO
var is_inside_fog = false

@export var grid_node: Node2D
@export var puzzle_ui: CanvasLayer # نود PuzzleUI را از پنل Scene به اینجا بکش
# تعریف مکان هر پازل روی نقشه

var puzzle_mapping = {
	Vector2i(3, 5): "season_start",
	Vector2i(3, 0): "algebra",
	Vector2i(1, 2): "wordsearch",
	Vector2i(2, 7): "murder",
	Vector2i(6, 2): "unboxing"
}

func _ready():
	update_position()
	# کمی صبر می‌کنیم تا Grid آماده شود
	await get_tree().process_frame
	if grid_node:
		grid_node.on_player_enter(grid_pos)
	else:
		print("ERROR: Grid Node is NOT connected to Player!")

func _process(_delta):
	var direction = Vector2i.ZERO
	
	if Input.is_action_just_pressed("ui_right"):
		direction = Vector2i(1, 0)
	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2i(0, 1)
	elif Input.is_action_just_pressed("ui_up"):
		direction = Vector2i(0, -1)
		
	if direction != Vector2i.ZERO:
		try_move(direction)

func try_move(direction: Vector2i):
	if grid_node == null or (puzzle_ui and puzzle_ui.visible): 
		return # اگر پازل باز است، بازیکن نباید حرکت کند
	
	var target_pos = grid_pos + direction
	
	if grid_node.can_move(grid_pos, direction):
		check_fog_logic(target_pos)
		grid_pos = target_pos
		
		# ۱. بررسی پورتال (سیاهچاله بنفش - جابجایی داخلی)
		if grid_pos in grid_node.portals:
			grid_pos = grid_node.portals[grid_pos]
			print("Portal jump!")

		# ۲. بررسی تله‌پورت (ستون - جابجایی به بخش دیگر)
		# در اینجا چک می‌کنیم اگر در لیست تله‌پورت‌ها بود، به تله‌پورت دیگر منتقل شود
		for i in range(grid_node.teleports.size()):
			if grid_pos == grid_node.teleports[i]:
				# جابجایی به تله‌پورت بعدی در لیست (یا اولی اگر به آخر رسیدیم)
				var next_index = (i + 1) % grid_node.teleports.size()
				grid_pos = grid_node.teleports[next_index]
				print("Teleporting to secret area...")
				break # خروج از حلقه بعد از جابجایی
		
		# ۳. ثبت ورود و آپدیت نهایی
		grid_node.on_player_enter(grid_pos)
		update_position()
		
	else:
		if is_wall_a_puzzle(grid_pos, direction):
			print("puzzle detected")
			open_puzzle_for_wall(grid_pos, direction)

func check_special_cells():
	# 1. بررسی پورتال (بنفش)
	if grid_pos in grid_node.portals:
		var destination = grid_node.portals[grid_pos]
		print("Teleporting through Portal to: ", destination)
		grid_pos = destination
		# اختیاری: اضافه کردن یک افکت صوتی یا تصویری اینجا
		
	# 2. بررسی تله‌پورت (ستون)
	elif grid_pos in grid_node.teleports:
		print("Entered Teleport Column!")
		# طبق داکیومنت، تله‌پورت بازیکن را به "خارج از نقشه" می‌برد
		# فعلاً می‌توانیم موقعیت را به یک مختصات خاص در بیرون ببریم
		# یا پیامی نمایش دهیم

func update_position():
	position = Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2
	)

func _draw():
	# رسم گوی بازیکن
	draw_circle(Vector2.ZERO, 18, Color.DARK_CYAN)
	# یک دایره سفید کوچک داخلش برای زیبایی
	draw_circle(Vector2(5, -5), 5, Color(1, 1, 1, 0.5))

func check_fog_logic(target: Vector2i):
	var target_is_fog = target in grid_node.fog_cells
	
	# لحظه ورود به مه از یک خانه عادی
	if target_is_fog and not is_inside_fog:
		last_safe_pos = grid_pos # ذخیره خانه قبل از مه برای بازگشت احتمالی
		is_inside_fog = true
		steps_in_fog = 1
		print("Entered Fog! Step 1")
	
	# حرکت دوم داخل مه
	elif target_is_fog and is_inside_fog:
		steps_in_fog += 1
		print("Inside Fog... Step ", steps_in_fog)
		
		if steps_in_fog > 2:
			# جریمه: بازگشت به عقب
			print("Lost in Fog! Returning to: ", last_safe_pos)
			grid_pos = last_safe_pos
			steps_in_fog = 0
			is_inside_fog = false
			# نکته: اینجا حرکت لغو می‌شود
	
	# خروج از مه به خانه عادی
	elif not target_is_fog and is_inside_fog:
		print("Exited Fog Safely!")
		is_inside_fog = false
		steps_in_fog = 0

func start_puzzle_sequence():
	# اینجا باید UI پازل را نمایش دهیم
	# فعلاً برای تست، فرض می‌کنیم بازیکن پازل را حل کرده است:
	grid_node.solved_puzzles.append(grid_pos)
	grid_node.queue_redraw()
	print("Wall Removed!")

# تابعی برای تشخیص اینکه آیا دیواری که به آن کوبیدیم پازل است یا خیر
func is_wall_a_puzzle(current_pos: Vector2i, dir: Vector2i) -> bool:
	# ۱. چک کردن دیوار سمت راست خانه فعلی
	if dir == Vector2i(1, 0):
		return current_pos in grid_node.right_puzzle_walls
	
	# ۲. چک کردن دیوار سمت چپ (که در واقع دیوار سمت راستِ خانه قبلی است)
	if dir == Vector2i(-1, 0):
		var left_neighbor = current_pos + Vector2i(-1, 0)
		return left_neighbor in grid_node.right_puzzle_walls
	
	# ۳. چک کردن دیوار پایین خانه 	فعلی
	if dir == Vector2i(0, 1):
		return current_pos in grid_node.bottom_puzzle_walls
	
	# ۴. چک کردن دیوار بالا (که در واقع دیوار پایینِ خانه بالایی است)
	if dir == Vector2i(0, -1):
		var top_neighbor = current_pos + Vector2i(0, -1)
		return top_neighbor in grid_node.bottom_puzzle_walls
	
	return false

func open_puzzle_for_wall(current_pos: Vector2i, dir: Vector2i):
	var puzzle_pos = current_pos
	if dir == Vector2i(-1, 0): puzzle_pos = current_pos + Vector2i(-1, 0)
	elif dir == Vector2i(0, -1): puzzle_pos = current_pos + Vector2i(0, -1)
	
	var p_type = puzzle_mapping.get(puzzle_pos)
	
	if p_type and puzzle_ui:
		puzzle_ui.open_puzzle(p_type)
		var result = await puzzle_ui.puzzle_solved
		
		if result == 1 or result == 2:
			# ۱. حذف از لیست پازل‌های پلیر (تا دوباره باز نشود)
			puzzle_mapping.erase(puzzle_pos)
			
			# ۲. حذف از دیتای اصلی ماز (تا راه باز شود)
			grid_node.remove_wall(current_pos, dir) 
			
			# ۳. اعمال امتیاز
			grid_node.apply_score_change(60 if result == 1 else 30)
			print("دیوار فیزیکی و منطقی حذف شد.")

# اضافه کردن این متغیرها به بالای اسکریپت Player خودتان
var has_time_diamond = false
var move_counter = 0

# اضافه کردن این تابع برای مدیریت خروج از مرحله (پازل ۵)
func exit_season():
	if GameManager:
		var has_season_item = GameManager.can_proceed_to_next_season()
		if has_season_item or has_time_diamond:
			if not has_season_item and has_time_diamond:
				has_time_diamond = false
				GameManager.use_time_diamond()
				
			GameManager.go_to_next_season_and_load()

# --- اتصال به سیستم دیوار ---
# این بخش را در جایی که برخورد با دیوار ۵ را چک می‌کنید قرار دهید:
func check_wall_interaction(puzzle_type):
	if puzzle_type == "season_exit":
		if GameManager.can_proceed_to_next_season() or has_time_diamond:
			return true # دیوار باز می‌شود
		else:
			print("برای باز کردن این در باید آیتم فصل را پیدا کنید!")
			return false
