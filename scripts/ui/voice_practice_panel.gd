extends PanelContainer
# Das einzige Sollwort steht direkt an seinem Pfeil.
# Eine kurze Pause trennt jede Aufforderung sichtbar von der nächsten.

signal selected(index: int)
const VoiceLevelMeter = preload("res://scripts/ui/voice_level_meter.gd")
const VoiceCompass = preload("res://scripts/ui/voice_compass.gd")
const INK := Color("142f3e")
const PAPER := Color("f4f5e9")
const MINT := Color("a9e2c8")
const ORANGE := Color("ed8651")
const TOTAL := 12
const PROMPT_RECTS := {
	"left": Rect2(-360, -34, 200, 68),
	"right": Rect2(160, -34, 200, 68),
	"faster": Rect2(-120, -232, 240, 64),
	"slower": Rect2(-120, 168, 240, 64)
}
var meter: Control
var calibration_prompt: Label
var calibration_instruction: Label
var compass: Control
var prompt: Label
var phase_label: Label
var feedback: Label
var score: Label
var counts: Label
var microphone: Label
var comparison: Label
var field: Control
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
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func centered(control: Control, parent: Control, rect: Rect2) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	control.offset_left = rect.position.x
	control.offset_right = rect.end.x
	control.offset_top = rect.position.y
	control.offset_bottom = rect.end.y

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 28
	offset_right = -28
	offset_top = 24
	offset_bottom = -24
	add_theme_stylebox_override("panel", box_style(INK, 26))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)
	var title := text_label(tr("I18N_MENU_VOICE_PRACTICE"), 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	layout.add_child(title)
	phase_label = text_label("", 22, MINT)
	layout.add_child(phase_label)
	field = Control.new()
	field.custom_minimum_size = Vector2(720, 470)
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(field)
	meter = VoiceLevelMeter.new()
	centered(meter, field, Rect2(-260, -40, 520, 210))
	calibration_instruction = text_label("", 21, MINT)
	calibration_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	centered(calibration_instruction, field, Rect2(-430, -240, 860, 70))
	calibration_prompt = text_label("", 48, PAPER)
	centered(calibration_prompt, field, Rect2(-400, -170, 800, 90))
	compass = VoiceCompass.new()
	centered(compass, field, Rect2(-140, -140, 280, 280))
	prompt = text_label("", 44, MINT)
	centered(prompt, field, PROMPT_RECTS.left)
	feedback = text_label("", 30)
	centered(feedback, field, Rect2(-24, -24, 48, 48))
	score = text_label("", 24, MINT)
	layout.add_child(score)
	counts = text_label("", 18)
	layout.add_child(counts)
	comparison = text_label("", 18)
	layout.add_child(comparison)
	microphone = text_label("", 18, ORANGE)
	microphone.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(microphone)
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

func mode_name(mode: String) -> String:
	return tr("I18N_PRACTICE_MODE_ONE") if mode == "direct" else tr("I18N_PRACTICE_MODE_TWO")

func word_text(word: String) -> String:
	match word:
		"left": return tr("I18N_PRACTICE_WORD_LEFT")
		"right": return tr("I18N_PRACTICE_WORD_RIGHT")
		"faster": return tr("I18N_PRACTICE_WORD_FAST")
		"slower": return tr("I18N_PRACTICE_WORD_SLOWER")
	return word

func result_text(mode: String, results: Dictionary) -> String:
	var result: Dictionary = results.get(mode, {})
	var attempted := int(result.get("attempted", 0))
	if attempted == 0: return tr("I18N_PRACTICE_COMPARE_EMPTY") % mode_name(mode)
	var correct := int(result.get("correct", 0))
	return tr("I18N_PRACTICE_COMPARE") % [mode_name(mode), correct, attempted, roundi(100.0 * correct / attempted)]

func render(value, voice_ready: bool, voice_status: String) -> void:
	session = value
	var practice = session.practice
	var phase: String = practice.phase
	var calibrating := phase == "calibrating"
	var done := phase == "done"
	var transition := phase == "transition"
	var active := phase in ["waiting", "listening", "transition", "calibrating"]
	compass.visible = not calibrating
	meter.visible = calibrating
	calibration_prompt.visible = calibrating
	calibration_instruction.visible = calibrating
	var expected: String = practice.last_expected if transition else practice.expected_word()
	prompt.visible = phase in ["listening", "transition"]
	prompt.text = word_text(expected)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if expected == "left" else (HORIZONTAL_ALIGNMENT_LEFT if expected == "right" else HORIZONTAL_ALIGNMENT_CENTER)
	if PROMPT_RECTS.has(expected):
		var rect: Rect2 = PROMPT_RECTS[expected]
		prompt.offset_left = rect.position.x
		prompt.offset_right = rect.end.x
		prompt.offset_top = rect.position.y
		prompt.offset_bottom = rect.end.y
	var elapsed: float = practice.TRANSITION_SECONDS - practice.remaining_s if transition else practice.WAIT_SECONDS - practice.remaining_s
	prompt.modulate.a = clampf(1.0 - elapsed / 0.18, 0.0, 1.0) if transition else clampf(elapsed / 0.18, 0.0, 1.0)
	phase_label.text = tr("I18N_PRACTICE_PROGRESS") % [mini(practice.attempted if transition else practice.attempted + 1, TOTAL), TOTAL] if active else ""
	phase_label.visible = active and phase != "waiting"
	feedback.visible = transition
	feedback.text = "✓" if practice.last_result == "correct" else "×"
	feedback.add_theme_color_override("font_color", MINT if practice.last_result == "correct" else ORANGE)
	feedback.modulate.a = clampf(elapsed / 0.12, 0.0, 1.0) if transition else 1.0
	var attempted: int = practice.attempted
	var accuracy := roundi(100.0 * practice.correct / attempted) if attempted > 0 else 0
	score.text = tr("I18N_PRACTICE_SCORE") % [practice.correct, attempted, accuracy]
	counts.text = tr("I18N_PRACTICE_COUNTS") % [practice.wrong, practice.missed]
	comparison.text = result_text("direct", practice.results) + "\n" + result_text("checked", practice.results)
	score.visible = done
	counts.visible = done
	comparison.visible = done
	field.custom_minimum_size.y = 280 if done else 470
	microphone.visible = not voice_ready
	microphone.text = tr("I18N_PRACTICE_WAITING") if phase == "waiting" else voice_status
	buttons[0].text = tr("I18N_PRACTICE_RESTART_SHORT") if active else (tr("I18N_PRACTICE_AGAIN") if done else tr("I18N_PRACTICE_START"))
	buttons[1].text = tr("I18N_PRACTICE_MODE") % mode_name(session.voice_mode)
	buttons[2].text = tr("I18N_PRACTICE_BACK")
	if calibrating:
		var calibration = practice.calibration
		var keys := ["I18N_CALIBRATION_NORMAL", "I18N_CALIBRATION_LOUDER", "I18N_CALIBRATION_LOUDEST"]
		calibration_prompt.text = tr("I18N_CALIBRATION_WORD")
		calibration_instruction.text = tr(calibration.error) if not calibration.error.is_empty() else tr(keys[calibration.stage])
		calibration_prompt.modulate.a = 1.0
		if calibration.phase == "transition":
			calibration_instruction.text = tr("I18N_CALIBRATION_SAVED")
			calibration_prompt.modulate.a = clampf(calibration.remaining_s / 0.18, 0.0, 1.0)
		phase_label.visible = true
		phase_label.text = tr("I18N_PRACTICE_PROGRESS") % [calibration.stage + 1, 3]
		meter.set_signal(calibration.display_level(), calibration.phase == "transition", 1.0 if calibration.phase == "transition" else float(calibration.samples.size()) / calibration.SAMPLE_COUNT)
	elif phase == "ready":
		buttons[0].text = tr("I18N_CALIBRATION_START")
	for index in range(buttons.size()):
		var current: bool = index == session.menu_index
		buttons[index].add_theme_stylebox_override("normal", box_style(MINT if current else Color("294553")))
		buttons[index].add_theme_color_override("font_color", INK if current else PAPER)
