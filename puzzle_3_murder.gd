extends Control

signal puzzle_finished(success: bool)

# =========================
# Data Classes
# =========================

class Suspect:
	var name: String
	var height: int
	var hair: String
	var skin: String
	var clothes: String
	var special: String
	var behavior: String
	var image_path: String

	func _init(n, h, ha, s, c, sp, b, img):
		name = n
		height = h
		hair = ha
		skin = s
		clothes = c
		special = sp
		behavior = b
		image_path = img


class Witness:
	var age: int
	var reliability: float
	var statements: Dictionary

	func _init(a, r, st):
		age = a
		reliability = r
		statements = st


# =========================
# Data (FULL – مثل اسکریپت خودت)
# =========================

var suspects := [
	Suspect.new("سارا نیک‌پور", 165, "مشکی کوتاه", "روشن", "کت چرمی مشکی",
		"تتو کوچک روی مچ دست راست", "سریع حرف می‌زند", "res://images/sara.png"),
	Suspect.new("آرش کمالی", 180, "قهوه‌ای", "گندمی", "هودی طوسی",
		"ماه‌گرفتگی روی ساعد چپ", "آرام و منطقی", "res://images/arash.png"),
	Suspect.new("پریسا رحیمی", 170, "بلوند", "روشن", "مانتوی سبز",
		"خال روی گردن", "مضطرب", "res://images/parisa.png"),
	Suspect.new("نیما مرادی", 175, "مشکی", "سبزه", "پیراهن آبی",
		"تتو بزرگ بازو", "پر حرف", "res://images/nima.png"),
	Suspect.new("مهسا شریفی", 160, "قرمز", "روشن", "کاپشن جین",
		"بدون ویژگی خاص", "کم‌حرف", "res://images/mahsa.png")
]

var witnesses: Array[Witness] = [
	Witness.new(27, 0.7, {
		"قد": "بین 165 تا 175 بود",
		"لباس": "تیره بود",
		"ویژگی": "فکر کنم روی مچ دستش یک تتو دیدم."
	}),
	Witness.new(65, 0.3, {
		"لباس": "فکر کنم آبی بود",
		"ویژگی": "مطمئن نیستم، شاید ماه گرفتگی روی دست چپ داشت. شاید هم روی گردنش یک خال داشت"
	}),
	Witness.new(40, 0.5, {
		"قد": "حدود 170 بود.",
		"مو": "تیره و فکر کنم کوتاه بود.",
		"ویژگی": "یک چیز خاص روی دستش دیدم اما مطمئن نیستم چی بود."
	})
]

const CORRECT_KILLER := "سارا نیک‌پور"

# =========================
# Nodes
# =========================

@onready var title_lbl: Label = $VBoxContainer/Title
@onready var suspect_grid: GridContainer = $VBoxContainer/HBoxContainer/SuspectsPanel
@onready var evidence_panel: VBoxContainer = $VBoxContainer/HBoxContainer/EvidencePanel
@onready var selector: OptionButton = $VBoxContainer/SuspectSelector
@onready var confirm_btn: Button = $VBoxContainer/ConfirmButton
@onready var result_lbl: Label = $VBoxContainer/ResultLabel



func _ready():
	title_lbl.text = "پازل قتل:"

	selector.clear()
	for s in suspects:
		selector.add_item(s.name)

	_style_ui()  # اضافه کردن استایل UI
	_build_suspects()
	_build_evidence()

	confirm_btn.pressed.connect(_on_confirm)

# -----------------------------
# زیباسازی UI
# -----------------------------
func _style_ui():
	# عنوان
	var title := $VBoxContainer/Title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#2c3e50"))

	# دکمه تایید
	var btn := $VBoxContainer/ConfirmButton
	btn.text = "تایید حدس"
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



func _build_suspects():
	for c in suspect_grid.get_children():
		c.queue_free()

	for s in suspects:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(220, 260)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var vbox := VBoxContainer.new()
		card.add_child(vbox)

		var img := TextureRect.new()
		img.custom_minimum_size = Vector2(120, 140)
		img.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if ResourceLoader.exists(s.image_path):
			img.texture = load(s.image_path)

		vbox.add_child(img)

		
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.text = \
			"نام: %s\nقد: %d\nلباس: %s\nویژگی: %s" % [
				s.name, s.height, s.clothes, s.special
			]

		vbox.add_child(lbl)

		suspect_grid.add_child(card)



func _build_evidence():
	for c in evidence_panel.get_children():
		c.queue_free()

	for i in range(witnesses.size()):
		var w := witnesses[i]

		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(0, 100)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var txt := "شاهد %d (اعتماد %.0f%%):\n" % [i + 1, w.reliability * 100]
		for k in w.statements:
			txt += "- %s: %s\n" % [k, w.statements[k]]

		lbl.text = txt
		evidence_panel.add_child(lbl)



func _on_confirm():
	var idx := selector.selected
	if idx == -1:
		return

	if suspects[idx].name == CORRECT_KILLER:
		result_lbl.text = "✅ درست گفتی! قاتل شناسایی شد."
		result_lbl.modulate = Color.GREEN
		puzzle_finished.emit(true)
	else:
		result_lbl.text = "❌ انتخاب اشتباه است."
		result_lbl.modulate = Color.RED
