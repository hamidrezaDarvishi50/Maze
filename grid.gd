extends Node2D

const GRID_SIZE = 9
const CELL_SIZE = 64
const WALL_THICKNESS = 4.0

# آرایه‌ها برای ذخیره محل دیوارها
# right_walls[y][x] = true یعنی خانه (x,y) سمت راستش دیوار دارد
var right_walls = []
# bottom_walls[y][x] = true یعنی خانه (x,y) پایینش دیوار دارد
var bottom_walls = []

var visits = [] # ذخیره تعداد بازدیدها

# تعریف انواع خانه‌های خاص
enum CellType {NORMAL, PORTAL, TELEPORT}

# امتیاز
var score := 2000
var bonus_score := 0
const SCORE_CAP := 2000
signal score_changed(current_score, bonus_score)

# دیکشنری پورتال‌ها: کلید خانه ورودی و مقدار خانه مقصد است
var portals = {
	Vector2i(3, 0): Vector2i(6, 5),
	Vector2i(6, 5): Vector2i(3, 0) 
}

# لیست خانه‌های تله‌پورت (ستون‌ها)
var teleports = [Vector2i(6, 0), Vector2i(1, 8)]

# مه
var fog_cells = []
var steps_in_fog = 0
var last_safe_pos = Vector2i.ZERO
var is_inside_fog = false

# ذخیره مکان دیوارهایی که پازل دارند
# Vector2i(x, y) مختصات خانه، و دیوار سمت راست (Right) یا پایین (Bottom) آن
var right_puzzle_walls = [Vector2i(3, 5)] 
var bottom_puzzle_walls = [Vector2i(3, 0), Vector2i(1, 2), Vector2i(2, 7), Vector2i(6, 2)]

# لیست پازل‌هایی که حل شده‌اند (تا دیوار حذف شود)
var solved_puzzles = []	

func setup_fog():
	# فرض می‌کنیم ردیف‌های ۳ تا ۵ و ستون‌های ۴ تا ۶ مه دارند (طبق عکس)
	for y in range(4, 8):
		for x in range(5, 7):
			fog_cells.append(Vector2i(x, y))

func _ready():
	# 1. مقداردهی اولیه آرایه‌ها (همه خالی)
	for y in range(GRID_SIZE):
		right_walls.append([])
		bottom_walls.append([])
		visits.append([])
		for x in range(GRID_SIZE):
			right_walls[y].append(false)
			bottom_walls[y].append(false)
			visits[y].append(0)
	
	# 2. تعریف دیوارهای ماز طبق عکس ارسالی
	setup_maze_walls()
	queue_redraw()
	setup_fog()

func setup_maze_walls():
	# نکته: مختصات به صورت (y, x) هستند.
	# دیوارهای عمودی (Right Walls) - نمونه‌برداری از عکس
	# ردیف 0
	right_walls[0][2] = true; right_walls[0][3] = true; right_walls[0][5] = true; right_walls[0][6] = true
	# ردیف 1
	right_walls[1][0] = true; right_walls[1][4] = true; right_walls[1][5] = true
	# ردیف 2
	right_walls[2][0] = true; right_walls[2][1] = true; right_walls[2][3] = true; right_walls[2][5] = true; right_walls[2][6] = true
	# ردیف 3
	right_walls[3][0] = true; right_walls[3][1] = true; right_walls[3][2] = true; right_walls[3][4] = true
	# ردیف 4 (ردیف ورودی)
	right_walls[4][1] = true; right_walls[4][2] = true; right_walls[4][3] = true; right_walls[4][4] = true
	# ردیف 5
	right_walls[5][0] = true; right_walls[5][1] = true; right_walls[5][2] = true; right_walls[5][3] = true; right_walls[5][6] = true; right_walls[5][7] = true
	# ردیف 6
	right_walls[6][0] = true; right_walls[6][1] = true; right_walls[6][4] = true; right_walls[6][6] = true
	# ردیف 7
	right_walls[7][0] = true; right_walls[7][6] = true
	# ردیف 8
	right_walls[8][1] = true
	
	# دیوارهای افقی (Bottom Walls)
	# ردیف 0
	bottom_walls[0][1] = true; bottom_walls[0][2] = true; bottom_walls[0][3] = true; bottom_walls[0][4] = true; bottom_walls[0][7] = true
	# ردیف 1
	bottom_walls[1][2] = true; bottom_walls[1][3] = true; bottom_walls[1][5] = true; bottom_walls[1][7] = true; bottom_walls[1][8] = true
	# ردیف 2
	bottom_walls[2][0] = true; bottom_walls[2][1] = true; bottom_walls[2][3] = true; bottom_walls[2][5] = true; bottom_walls[2][6] = true
	# ردیف 3
	bottom_walls[3][3] = true; bottom_walls[3][4] = true; bottom_walls[3][6] = true; bottom_walls[3][7] = true; bottom_walls[3][8] = true
	# ردیف 4
	bottom_walls[4][4] = true; bottom_walls[4][6] = true; bottom_walls[4][8] = true
	# ردیف 5
	bottom_walls[5][3] = true; bottom_walls[5][4] = true; 	bottom_walls[5][5] = true; bottom_walls[5][7] = true
	# ردیف 6
	bottom_walls[6][1] = true; bottom_walls[6][2] = true; bottom_walls[6][3] = true; bottom_walls[6][6] = true
	# ردیف 7
	bottom_walls[7][1] = true; bottom_walls[7][2] = true; bottom_walls[7][3] = true; bottom_walls[7][4] = true; bottom_walls[7][5] = true; bottom_walls[7][6] = true

func _draw():
	# 1. رسم پس‌زمینه سفید (این بخش جدید است)
	# یک مستطیل به اندازه کل گرید رسم می‌کنیم
	draw_rect(Rect2(0, 0, GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE), Color.WHITE)

	# 2. رسم خطوط شبکه (رنگ را کمی تیره‌تر کردم تا روی سفید دیده شود)
	for i in range(GRID_SIZE + 1):
		var pos = i * CELL_SIZE
		# رنگ خطوط را از 0.9 به 0.8 تغییر دادم تا روی سفید مشخص باشد
		var grid_color = Color(0.85, 0.85, 0.85) 
		draw_line(Vector2(pos, 0), Vector2(pos, GRID_SIZE * CELL_SIZE), grid_color, 1.0)
		draw_line(Vector2(0, pos), Vector2(GRID_SIZE * CELL_SIZE, pos), grid_color, 1.0)

	# 3. رسم رنگ خانه‌های بازدید شده (زرد/قرمز)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if visits[y][x] >= 2:
				var color = Color.YELLOW if visits[y][x] == 2 else Color.RED
				draw_rect(Rect2(x * CELL_SIZE + 2, y * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4), color)

	# 4. رسم دیوارهای اصلی (مشکی ضخیم)
	var wall_color = Color.BLACK
	
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell_tl = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			var cell_br = Vector2((x + 1) * CELL_SIZE, (y + 1) * CELL_SIZE)
			
			if right_walls[y][x]:
				draw_line(Vector2(cell_br.x, cell_tl.y), cell_br, wall_color, WALL_THICKNESS)
			
			if bottom_walls[y][x]:
				draw_line(Vector2(cell_tl.x, cell_br.y), cell_br, wall_color, WALL_THICKNESS)

	# رسم کادر دور کل زمین
	draw_rect(Rect2(0, 0, GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE), wall_color, false, WALL_THICKNESS)
	
	# رسم پورتال‌ها و تله‌پورت‌ها
	for p in portals.keys():
		draw_circle(Vector2(p.x * CELL_SIZE + 32, p.y * CELL_SIZE + 32), 15, Color.PURPLE)
	
	for t in teleports:
		# رسم یک مربع کوچک برای تله‌پورت (نماد ستون)
		draw_rect(Rect2(t.x * CELL_SIZE + 16, t.y * CELL_SIZE + 16, 32, 32), Color.DARK_GOLDENROD)
	
	for cell in fog_cells:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color(0.5, 0.5, 0.5, 1.0)) # خاکستری تیره با غلظت ۸۰٪
	
	for p in right_puzzle_walls:
		if not p in solved_puzzles:
			var pos = Vector2((p.x + 1) * CELL_SIZE, p.y * CELL_SIZE + CELL_SIZE/2)
			draw_circle(pos, 8, Color.BROWN) # علامت قرمز برای پازل
		
	for p in bottom_puzzle_walls:
		if not p in solved_puzzles:
			var pos = Vector2(p.x * CELL_SIZE + CELL_SIZE/2, (p.y + 1) * CELL_SIZE)
			draw_circle(pos, 8, Color.BROWN)
	
	
# تابع بررسی حرکت: حالا جهت حرکت را می‌گیرد نه فقط مقصد را
func can_move(current: Vector2i, direction: Vector2i) -> bool:
	var target = current + direction
	
	# 1. بیرون زدن از صفحه
	if target.x < 0 or target.x >= GRID_SIZE or target.y < 0 or target.y >= GRID_SIZE:
		return false
	
	# 2. بررسی دیوار بین دو خانه
	# حرکت به راست (1, 0)
	if direction == Vector2i(1, 0):
		if right_walls[current.y][current.x]: return false
	
	# حرکت به چپ (-1, 0) -> باید دیوار راست خانه قبلی را چک کنیم
	elif direction == Vector2i(-1, 0):
		if right_walls[target.y][target.x]: return false
		
	# حرکت به پایین (0, 1)
	if direction == Vector2i(0, 1):
		if bottom_walls[current.y][current.x]: return false
		
	# حرکت به بالا (0, -1) -> باید دیوار پایین خانه بالایی را چک کنیم
	elif direction == Vector2i(0, -1):
		if bottom_walls[target.y][target.x]: return false

	# 3. بررسی قفل بودن خانه (قرمز)
	if visits[target.y][target.x] >= 3:
		return false
		
	return true

func on_player_enter(cell: Vector2i):
	if cell in fog_cells:
	# 1. هزینه پایه حرکت	
		apply_score_change(-10)
	
	else:
			# 1. هزینه پایه حرکت
		apply_score_change(-10)
		# 2. ثبت ورود
		visits[cell.y][cell.x] += 1
		# 3. جریمه خانه‌ها
		match visits[cell.y][cell.x]:
			2:
				apply_score_change(-10) # خانه زرد
			3:
				apply_score_change(-30) # خانه قرمز

		queue_redraw()

func apply_score_change(amount: int):
	if amount > 0 and score >= SCORE_CAP:
		bonus_score += amount
	else:
		score += amount
		if score > SCORE_CAP:
			bonus_score += score - SCORE_CAP
			score = SCORE_CAP
		if score < 0:
			score = 0

	score_changed.emit(score, bonus_score)
	print("Score:", score, " Bonus:", bonus_score)
	
func remove_wall(cell: Vector2i, direction: Vector2i):
	var target_cell = cell
	
	# اصلاح مختصات: دیوار سمت چپ شما، در واقع دیوار سمت راستِ خانه قبلی است
	if direction == Vector2i(-1, 0): # چپ
		target_cell = cell + Vector2i(-1, 0)
		if target_cell.x >= 0:
			right_walls[target_cell.y][target_cell.x] = false
			right_puzzle_walls.erase(target_cell)
			
	elif direction == Vector2i(1, 0): # راست
		right_walls[cell.y][cell.x] = false
		right_puzzle_walls.erase(cell)
		
	elif direction == Vector2i(0, -1): # بالا
		target_cell = cell + Vector2i(0, -1)
		if target_cell.y >= 0:
			bottom_walls[target_cell.y][target_cell.x] = false
			bottom_puzzle_walls.erase(target_cell)
			
	elif direction == Vector2i(0, 1): # پایین
		bottom_walls[cell.y][cell.x] = false
		bottom_puzzle_walls.erase(cell)

	queue_redraw() # اجبار به حذف تصویر دیوار
