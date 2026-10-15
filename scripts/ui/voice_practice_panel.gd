extends PanelContainer
# Die Übung übernimmt Farben und Tasten aus den vorhandenen Menüs.
# Das Sollwort führt links; rechts zeigt das beschriftete Kreuz die Spracheingabe.

signal selected(index: int)

const VoiceCompass = preload("res://scripts/ui/voice_compass.gd")
const INK := Color("142f3e")
const PAPER := Color("f4f5e9")
const MINT := Color("a9e2c8")
const ORANGE := Color("ed8651")
const TOTAL := 12

var compass: Control
var prompt: Label
var phase_label: Label
var feedback: Label
var score: Label
var counts: Label
var microphone: Label
var mode_help: Label
var comparison: Label
var progress: ProgressBar
var buttons: Array[Button] = []
var session

func box_style(color: Color, padding: int = 18) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(8)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = 12
	result.content_margin_bottom = 12
	return result

func text_label(value: String, font_size: int, color: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 28
	offset_right = -28
	offset_top = 24
	offset_bottom = -24
	add_theme_stylebox_override("panel", box_style(Color("142f3efc"), 26))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 20)
	layout.add_child(heading)
	var title := text_label(tr("I18N_PRACTICE_TITLE"), 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var brand := text_label(tr("I18N_APP_BRAND"), 17, MINT)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.add_child(brand)
	layout.add_child(text_label(tr("I18N_PRACTICE_HELP"), 18, MINT))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	var task := VBoxContainer.new()
	task.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task.size_flags_stretch_ratio = 1.3
	task.add_theme_constant_override("separation", 7)
	columns.add_child(task)
	phase_label = text_label("", 18, MINT)
	task.add_child(phase_label)
	prompt = text_label("", 56)
	prompt.custom_minimum_size.y = 70
	task.add_child(prompt)
	feedback = text_label("", 19)
	feedback.custom_minimum_size.y = 46
	task.add_child(feedback)
	score = text_label("", 24, MINT)
	task.add_child(score)
	counts = text_label("", 18)
	task.add_child(counts)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 5
	progress.max_value = TOTAL
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_background := box_style(Color("294553"), 0)
	bar_background.content_margin_top = 0
	bar_background.content_margin_bottom = 0
	var bar_fill := box_style(MINT, 0)
	bar_fill.content_margin_top = 0
	bar_fill.content_margin_bottom = 0
	progress.add_theme_stylebox_override("background", bar_background)
	progress.add_theme_stylebox_override("fill", bar_fill)
	task.add_child(progress)
	microphone = text_label("", 16, MINT)
	microphone.custom_minimum_size.y = 40
	task.add_child(microphone)
	var voice := VBoxContainer.new()
	voice.custom_minimum_size.x = 320
	voice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	voice.add_theme_constant_override("separation", 4)
	columns.add_child(voice)
	var voice_title := text_label(tr("I18N_PRACTICE_COMPASS"), 18, MINT)
	voice_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voice.add_child(voice_title)
	var field := Control.new()
	field.custom_minimum_size = Vector2(320, 250)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voice.add_child(field)
	compass = VoiceCompass.new()
	compass.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	compass.offset_left = -88
	compass.offset_right = 88
	compass.offset_top = -88
	compass.offset_bottom = 88
	field.add_child(compass)
	compass_word(field, "I18N_PRACTICE_WORD_FASTER", Vector2(0.5, 0.5), Rect2(-75, -125, 150, 30))
	compass_word(field, "I18N_PRACTICE_WORD_SLOWER", Vector2(0.5, 0.5), Rect2(-75, 95, 150, 30))
	compass_word(field, "I18N_PRACTICE_WORD_LEFT", Vector2(0.5, 0.5), Rect2(-160, -15, 70, 30))
	compass_word(field, "I18N_PRACTICE_WORD_RIGHT", Vector2(0.5, 0.5), Rect2(90, -15, 70, 30))
	comparison = text_label("", 17)
	comparison.custom_minimum_size.y = 44
	layout.add_child(comparison)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	for index in range(3):
		var button := Button.new()
		button.custom_minimum_size.y = 48
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_stylebox_override("hover", box_style(Color("bfe8d8")))
		button.add_theme_stylebox_override("pressed", box_style(MINT))
		button.add_theme_color_override("font_hover_color", INK)
		button.add_theme_color_override("font_pressed_color", INK)
		button.pressed.connect(func(): selected.emit(index))
		button.mouse_entered.connect(func():
			if session != null: session.menu_index = index
		)
		actions.add_child(button)
		buttons.append(button)
	mode_help = text_label("", 16, MINT)
	layout.add_child(mode_help)

func compass_word(parent: Control, key: String, anchor: Vector2, rect: Rect2) -> void:
	var word := text_label(tr(key), 18)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word.anchor_left = anchor.x
	word.anchor_right = anchor.x
	word.anchor_top = anchor.y
	word.anchor_bottom = anchor.y
	word.offset_left = rect.position.x
	word.offset_right = rect.end.x
	word.offset_top = rect.position.y
	word.offset_bottom = rect.end.y
	parent.add_child(word)

func mode_name(mode: String) -> String:
	return tr("I18N_PRACTICE_MODE_ONE") if mode == "direct" else tr("I18N_PRACTICE_MODE_TWO")

func word_text(word: String) -> String:
	match word:
		"left": return tr("I18N_PRACTICE_WORD_LEFT")
		"right": return tr("I18N_PRACTICE_WORD_RIGHT")
		"faster": return tr("I18N_PRACTICE_WORD_FASTER")
		"slower": return tr("I18N_PRACTICE_WORD_SLOWER")
	return word

func result_text(mode: String, results: Dictionary) -> String:
	var result: Dictionary = results.get(mode, {})
	var attempted := int(result.get("attempted", 0))
	if attempted == 0:
		return tr("I18N_PRACTICE_COMPARE_EMPTY") % mode_name(mode)
	var correct := int(result.get("correct", 0))
	return tr("I18N_PRACTICE_COMPARE") % [mode_name(mode), correct, attempted, roundi(100.0 * correct / attempted)]

func render(value, voice_ready: bool, voice_status: String) -> void:
	session = value
	var practice = session.practice
	var phase: String = practice.phase
	var active := phase in ["waiting", "listening", "transition"]
	var expected: String = practice.expected_word()
	prompt.text = word_text(expected).to_upper() if not expected.is_empty() else tr("I18N_PRACTICE_COMPLETE")
	if phase == "ready":
		prompt.text = tr("I18N_PRACTICE_READY")
		phase_label.text = tr("I18N_PRACTICE_PLAN")
	elif phase == "waiting":
		phase_label.text = tr("I18N_PRACTICE_WAITING")
	elif phase == "listening":
		phase_label.text = tr("I18N_PRACTICE_SAY") % [mini(practice.attempted + 1, TOTAL), TOTAL, maxf(0.0, practice.remaining_s)]
	elif phase == "transition":
		phase_label.text = tr("I18N_PRACTICE_NEXT")
	else:
		phase_label.text = tr("I18N_PRACTICE_DONE")
	var result := ""
	match practice.last_result:
		"correct": result = tr("I18N_PRACTICE_CORRECT")
		"wrong": result = tr("I18N_PRACTICE_WRONG")
		"missed": result = tr("I18N_PRACTICE_UNKNOWN") if not practice.last_heard.is_empty() else tr("I18N_PRACTICE_MISSED")
	var heard: String = practice.last_heard
	feedback.text = tr("I18N_PRACTICE_HEARD") % word_text(heard) if not heard.is_empty() else tr("I18N_PRACTICE_NO_WORD")
	if not result.is_empty(): feedback.text = result + "\n" + feedback.text
	feedback.add_theme_color_override("font_color", MINT if practice.last_result == "correct" else (ORANGE if not result.is_empty() else PAPER))
	var attempted: int = practice.attempted
	var accuracy := roundi(100.0 * practice.correct / attempted) if attempted > 0 else 0
	score.text = tr("I18N_PRACTICE_SCORE") % [practice.correct, attempted, accuracy]
	counts.text = tr("I18N_PRACTICE_COUNTS") % [practice.wrong, practice.missed]
	progress.value = attempted
	microphone.text = tr("I18N_PRACTICE_MICROPHONE") % voice_status
	microphone.add_theme_color_override("font_color", MINT if voice_ready else ORANGE)
	comparison.text = result_text("direct", practice.results) + "\n" + result_text("checked", practice.results)
	buttons[0].text = tr("I18N_PRACTICE_RESTART") if active else (tr("I18N_PRACTICE_AGAIN") if phase == "done" or attempted > 0 else tr("I18N_PRACTICE_START"))
	buttons[1].text = tr("I18N_PRACTICE_MODE") % mode_name(session.voice_mode)
	buttons[2].text = tr("I18N_PRACTICE_BACK")
	mode_help.text = tr("I18N_PRACTICE_DIRECT_HELP") if session.voice_mode == "direct" else tr("I18N_PRACTICE_CHECKED_HELP")
	for index in range(buttons.size()):
		var current: bool = index == session.menu_index
		buttons[index].add_theme_stylebox_override("normal", box_style(MINT if current else Color("294553")))
		buttons[index].add_theme_color_override("font_color", INK if current else PAPER)
