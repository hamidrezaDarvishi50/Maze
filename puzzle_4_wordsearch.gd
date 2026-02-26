extends Control

signal puzzle_finished(success: bool)

const GRID_SIZE := 10

# جواب‌های درست
var correct_answers := [
	"دانش",
	"کتاب",
	"باله",
	"زهرا",
	"قلمی",
	"هرات"
]

# جدول ثابت
var grid := [
	["ف","م","ب","ه","ا","گ","ش","ن","ا","د"],
	["و","خ","س","ت","خ","د","ر","پ","ز","ی"],
	["ت","ا","و","ن","ف","ل","ب","ا","ت","ک"],
	["ب","ل","چ","ر","ر","پ","ص","ق","م","س"],
	["ا","ز","ی","ن","ش","و","ج","ه","ا","ا"],
	["ل","ه","ق","ل","م","ی","ک","س","ش","ب"],
	["ه","ر","ا","ت","س","پ","د","و","ی","ت"],
	["و","ا","ی","ر","د","ق","ض","ف","ن","ن"],
	["پ","ت","ش","ه","س","ر","د","م","ف","ر"],
	["ه","و","ک","ا","ن","ب","ت","س","ل","گ"]
]

func _ready():
	$VBoxContainer/SubmitButton.pressed.connect(_on_submit)
	_style_ui()
	_draw_grid()

# -----------------------------
# زیباسازی UI
# -----------------------------
func _style_ui():
	# عنوان
	var title := $VBoxContainer/Label
	title.text = "پازل واژه‌یابی"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#2c3e50"))

	# دکمه
	var btn := $VBoxContainer/SubmitButton
	btn.text = "بررسی پاسخ"
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#3498db")
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8

	btn_style.content_margin_left = 12
	btn_style.content_margin_right = 12
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", btn_style)

# -----------------------------
# نمایش جدول
# -----------------------------
func _draw_grid():
	var grid_node := $VBoxContainer/LetterGrid
	grid_node.columns = GRID_SIZE

	for child in grid_node.get_children():
		child.queue_free()

	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			var lbl := Label.new()
			lbl.text = grid[i][j]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.custom_minimum_size = Vector2(42, 42)
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", Color("#2c3e50"))

			var cell_style := StyleBoxFlat.new()
			cell_style.bg_color = Color("#ecf0f1")
			cell_style.border_color = Color("#bdc3c7")
			cell_style.border_width_top = 1
			cell_style.border_width_bottom = 1
			cell_style.border_width_left = 1
			cell_style.border_width_right = 1
			cell_style.corner_radius_top_left = 4
			cell_style.corner_radius_top_right = 4
			cell_style.corner_radius_bottom_left = 4
			cell_style.corner_radius_bottom_right = 4
			lbl.add_theme_stylebox_override("normal", cell_style)

			grid_node.add_child(lbl)

# -----------------------------
# بررسی پاسخ
# -----------------------------
func _on_submit():
	var answer: String = $VBoxContainer/AnswerInput.text.strip_edges()

	if answer in correct_answers:
		print("Correct!")
		puzzle_finished.emit(true)
		queue_free()
	else:
		print("Wrong!")
