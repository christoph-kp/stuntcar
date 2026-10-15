extends CanvasLayer

signal menu_selected(index: int)
const TrackSelection = preload("res://scripts/ui/track_selection.gd")
var track_selection: PanelContainer
const INK := Color("142f3e")
const PAPER := Color("f4f5e9")
const MINT := Color("a9e2c8")
var root: Control
var hud: Control
var menu_panel: PanelContainer
var menu_title: Label
var menu_subtitle: Label
var menu_buttons: VBoxContainer
var menu_footer: Label
var route_label: Label
var time_label: Label
var hint_label: Label
var hint_detail: Label
var keys_label: Label
var status_label: Label
var voice_label: Label
var voice_text := "Sprache aus"
var voice_visible := false
var voice_level := 0.0
var voice_device := ""
var voice_heard := ""
var voice_feedback_state := "listening"
var voice_action := ""
var speech_panel: PanelContainer
var speech_device: Label
var speech_level: ProgressBar
var speech_heard: Label
var speech_action: Label
var progress: ProgressBar
var minimap: Control
var current_menu := ""
var current_entries: Array[String] = []
var buttons: Array[Button] = []
var left_name := "A"
var right_name := "D"

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 20
	root.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top := panel(hud, Color("142f3ef5"))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 28
	top.offset_right = -28
	top.offset_top = 24
	top.offset_bottom = 88
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 30)
	top.add_child(top_row)
	var brand := label("STUNTCAR", 23, PAPER)
	top_row.add_child(brand)
	route_label = label("Erste Fahrt  /  600 m", 19, MINT)
	route_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(route_label)
	time_label = label("00:00", 24, PAPER)
	top_row.add_child(time_label)
	progress = ProgressBar.new()
	progress.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	progress.offset_left = 30
	progress.offset_right = -30
	progress.offset_top = 91
	progress.offset_bottom = 95
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", style(Color("142f3e40"), 0, 0))
	progress.add_theme_stylebox_override("fill", style(Color("ed8651"), 0, 0))
	hud.add_child(progress)
	var hint_box := VBoxContainer.new()
	hint_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hint_box.offset_left = -300
	hint_box.offset_right = 300
	hint_box.offset_top = 128
	hint_box.add_theme_constant_override("separation", 5)
	hud.add_child(hint_box)
	hint_label = label("", 36, INK)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", PAPER)
	hint_label.add_theme_color_override("font_outline_color", INK)
	hint_label.add_theme_constant_override("outline_size", 8)
	hint_box.add_child(hint_label)
	hint_detail = label("", 20, INK)
	hint_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_detail.add_theme_color_override("font_color", PAPER)
	hint_detail.add_theme_color_override("font_outline_color", INK)
	hint_detail.add_theme_constant_override("outline_size", 6)
	hint_box.add_child(hint_detail)
	var bottom := panel(hud, Color("142f3ef5"))
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_right = -28
	bottom.offset_top = -124
	bottom.offset_bottom = -24
	var bottom_row := VBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 4)
	bottom.add_child(bottom_row)
	keys_label = label("", 22, PAPER)
	keys_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_row.add_child(keys_label)
	status_label = label("", 16, MINT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom_row.add_child(status_label)
	voice_label = label("Sprache aus", 16, MINT)
	voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	voice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_row.add_child(voice_label)
	speech_panel = panel(hud, Color("142f3ef5"))
	speech_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	speech_panel.offset_left = -418
	speech_panel.offset_right = -28
	speech_panel.offset_top = -76
	speech_panel.offset_bottom = 160
	speech_panel.visible = false
	var speech_rows := VBoxContainer.new()
	speech_rows.add_theme_constant_override("separation", 8)
	speech_panel.add_child(speech_rows)
	speech_rows.add_child(label("DEINE SPRACHE", 17, MINT))
	speech_device = label("", 14, PAPER)
	speech_device.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	speech_rows.add_child(speech_device)
	speech_level = ProgressBar.new()
	speech_level.show_percentage = false
	speech_level.custom_minimum_size.y = 8
	speech_level.add_theme_stylebox_override("background", style(Color("294553"), 0, 0))
	speech_level.add_theme_stylebox_override("fill", style(MINT, 0, 0))
	speech_rows.add_child(speech_level)
	speech_heard = label("", 20, PAPER)
	speech_heard.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_heard.custom_minimum_size = Vector2(340, 50)
	speech_rows.add_child(speech_heard)
	speech_action = label("", 18, MINT)
	speech_action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech_rows.add_child(speech_action)
	menu_panel = panel(root, Color("142f3ef5"))
	menu_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	menu_panel.offset_left = 48
	menu_panel.offset_top = -290
	menu_panel.offset_right = 492
	menu_panel.offset_bottom = 230
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	menu_panel.add_child(content)
	content.add_child(label("STUNTCAR", 16, MINT))
	menu_title = label("Deine Richtung.\nDeine Fahrt.", 34, PAPER)
	content.add_child(menu_title)
	menu_subtitle = label("", 19, Color("d0dedb"))
	menu_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_subtitle.custom_minimum_size = Vector2(365, 64)
	content.add_child(menu_subtitle)
	menu_buttons = VBoxContainer.new()
	menu_buttons.add_theme_constant_override("separation", 8)
	content.add_child(menu_buttons)
	menu_footer = label("", 15, MINT)
	menu_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(menu_footer)
	track_selection = TrackSelection.new()
	root.add_child(track_selection)
	track_selection.selected.connect(func(index): menu_selected.emit(index))

func style(color: Color, radius: int = 8, padding: int = 20) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = 12
	result.content_margin_bottom = 12
	return result

func panel(parent: Control, color: Color) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", style(color))
	parent.add_child(result)
	return result

func label(text: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result

func render(session, rebind_message: String = "") -> void:
	track_selection.visible = session.state == "TRACKS"
	hud.visible = session.state != "TRACKS"
	if session.state == "TRACKS":
		menu_panel.visible = false
		track_selection.render(session, left_name, right_name, voice_text)
		return
	voice_label.text = voice_text
	speech_panel.visible = voice_visible
	speech_device.text = voice_device if not voice_device.is_empty() else "Das Mikrofon startet …"
	speech_level.value = voice_level * 100.0
	speech_heard.text = "Ich höre: %s" % voice_heard if not voice_heard.is_empty() else "Sprich: links, links, links …"
	if voice_feedback_state == "checking" and not voice_heard.is_empty():
		speech_heard.text = "Prüfe: %s" % voice_heard
	elif voice_feedback_state == "unknown":
		speech_heard.text = "Unklar: %s" % voice_heard if not voice_heard.is_empty() else "Kein Befehl erkannt."
	speech_action.text = voice_action
	var model = session.model
	var state: String = session.state
	var driving := state in ["RUNNING", "FALLING"]
	menu_panel.visible = not driving
	hint_label.visible = driving
	hint_detail.visible = driving
	progress.value = model.distance_m / model.track.length_m * 100.0
	var speed_text := "%d km/h" % (roundi(model.speed_mps * 3.6) if driving else 0)
	if driving and absf(model.target_speed_mps - model.speed_mps) > 0.3:
		speed_text = "%d → %d km/h" % [roundi(model.speed_mps * 3.6), roundi(model.target_speed_mps * 3.6)]
	time_label.text = "%s · %02d:%02d" % [speed_text, int(session.total_time + model.elapsed_s) / 60, int(session.total_time + model.elapsed_s) % 60]
	route_label.text = "%s  /  %d von %d m" % [model.track.track_name, int(model.distance_m), int(model.track.length_m)]
	var curve: Dictionary = model.track.next_curve(model.distance_m)
	var near_curve: bool = not curve.is_empty() and curve.start_m - model.distance_m <= model.input_window_m()
	keys_label.text = "[ %s ]   Links                 Rechts   [ %s ]" % [left_name, right_name]
	status_label.text = "Kurz drücken: lenken  ·  Erneut drücken: nachkorrigieren  ·  Esc: Pause"
	if session.voice_enabled:
		status_label.text = "Sagen: links · rechts · schneller / Gas · langsamer / Bremsen · Pause"
	if state == "FALLING":
		hint_label.text = "Die Strecke verlassen"
		hint_detail.text = "Du fährst gleich vor der Kurve weiter."
	elif model.active_curve_id >= 0:
		hint_label.text = "←  Links gewählt" if model.track.curves[model.active_curve_id].turn_sign < 0 else "Rechts gewählt  →"
		if model.correction_remaining > 0.0:
			hint_detail.text = "Deine Korrektur zieht das Auto nach innen."
		elif absf(model.lateral) > 1.6:
			hint_detail.text = "Knapp am Rand! Kurz nachkorrigieren."
		else:
			hint_detail.text = "Die Kurve kommt. Deine Richtung ist gewählt."
	elif near_curve:
		hint_label.text = "←  Linkskurve" if curve.turn_sign < 0 else "Rechtskurve  →"
		hint_detail.text = "Gib jetzt die Richtung vor."
	else:
		hint_label.text = "Geradeaus"
		hint_detail.text = "Hier brauchst du nicht zu lenken."
	var jump: Dictionary = model.track.jump_for_correction(model.distance_m)
	if state == "RUNNING" and not jump.is_empty():
		hint_label.text = "In der Luft!" if model.airborne else ("Gelandet!" if model.distance_m >= jump.end_m else "Sprung voraus")
		if model.lateral > 0.7:
			hint_detail.text = "Kurz links korrigieren für die Landung."
		elif model.lateral < -0.7:
			hint_detail.text = "Kurz rechts korrigieren für die Landung."
		else:
			hint_detail.text = "Du bist ausgerichtet. Das Tempo reicht."
	if driving and model.speed_feedback_seconds > 0.0:
		status_label.text = model.speed_feedback
	elif driving and model.speed_mps > 30.0:
		status_label.text = "Hohes Tempo: In Kurven nachkorrigieren oder langsamer fahren."
	if driving:
		current_menu = ""
		return
	keys_label.text = "[ %s ]   Nächster Eintrag             Auswählen   [ %s ]" % [left_name, right_name]
	status_label.text = "Alle Menüs funktionieren mit diesen zwei Tasten."
	if session.voice_enabled:
		status_label.text = "Sagen: Start · nächstes · wählen · weiter"
	match state:
		"MENU":
			menu_title.text = "Deine Richtung.\nDeine Fahrt."
			menu_subtitle.text = model.track.track_name + "\n" + model.track.description
		"PAUSED":
			menu_title.text = "Eine kurze Pause."
			menu_subtitle.text = "Die Fahrt wartet auf dich."
		"FINISHED":
			menu_title.text = "Du hast es geschafft."
			menu_subtitle.text = "%d Meter · %d Kurven\n%d erneute Versuche" % [int(model.track.length_m), model.track.curves.size(), session.retry_count]
		"CONTROL":
			menu_title.text = "Deine Steuerung."
			menu_subtitle.text = "Wähle deine Steuerung. Du kannst sie später in den Einstellungen ändern."
		"TRACKS":
			menu_title.text = "Deine Strecke."
			var routes: Array = session.routes
			menu_subtitle.text = routes[session.menu_index].description if session.menu_index < routes.size() else "Zurück zur aktuellen Strecke."
		"SETTINGS":
			menu_title.text = "Deine Einstellungen."
			menu_subtitle.text = rebind_message if not rebind_message.is_empty() else "Wähle genug Zeit für deine Eingabe."
	menu_footer.text = "Ohne Eingabe fährt das Auto geradeaus.\nVor jeder Kurve zählt deine Richtung."
	if state == "CONTROL":
		menu_footer.text = "%s: Auswahl wechseln · %s: Bestätigen\nDu kannst auch einen Eintrag anklicken.\nSprache nutzt dein Mikrofon. Die Erkennung läuft auf diesem Rechner." % [left_name, right_name]
	var entries: Array[String] = session.entries()
	if current_menu != state or entries != current_entries:
		for button in buttons:
			button.queue_free()
		buttons.clear()
		for i in range(entries.size()):
			var button := Button.new()
			button.text = entries[i]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size = Vector2(0, 46)
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_font_size_override("font_size", 20)
			button.add_theme_stylebox_override("hover", style(Color("bfe8d8")))
			button.add_theme_color_override("font_hover_color", INK)
			button.pressed.connect(func(): menu_selected.emit(i))
			menu_buttons.add_child(button)
			buttons.append(button)
		current_menu = state
		current_entries = entries.duplicate()
	for i in range(buttons.size()):
		buttons[i].add_theme_stylebox_override("normal", style(MINT if i == session.menu_index else Color("294553")))
		buttons[i].add_theme_color_override("font_color", INK if i == session.menu_index else PAPER)
		buttons[i].disabled = not rebind_message.is_empty()
