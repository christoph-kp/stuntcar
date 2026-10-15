extends PanelContainer
# Die vorhandenen Farben bleiben erhalten. Das Bild zeigt die ausgewählte Strecke.
# Die linke Liste bleibt mit zwei Tasten bedienbar und kann beliebig lang werden.

signal selected(index: int)
const Scenarios = preload("res://scripts/track/scenarios.gd")
const INK := Color("142f3e")
const PAPER := Color("f4f5e9")
const MINT := Color("a9e2c8")
var routes_column: VBoxContainer
var scroll: ScrollContainer
var picture: TextureRect
var route_title: Label
var landscape_label: Label
var description: Label
var facts: Label
var caption: Label
var footer: Label
var voice_status: Label
var errors: RichTextLabel
var buttons: Array[Button] = []
var textures := {}
var previous_entries: Array[String] = []
var previous_routes: Array[Dictionary] = []
var previous_index := -1
var session

func box_style(color: Color, padding: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func text_label(value: String, size: int, color: Color = PAPER) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 28
	offset_right = -28
	offset_top = 24
	offset_bottom = -24
	add_theme_stylebox_override("panel", box_style(Color("142f3efc"), 26))
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	add_child(layout)
	layout.add_child(text_label("STUNTCAR", 17, MINT))
	layout.add_child(text_label("Wohin geht deine Fahrt?", 36))
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size.x = 360
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 0.8
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	routes_column = VBoxContainer.new()
	routes_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	routes_column.add_theme_constant_override("separation", 8)
	scroll.add_child(routes_column)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_stretch_ratio = 1.3
	detail.add_theme_constant_override("separation", 10)
	columns.add_child(detail)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.custom_minimum_size.y = 200
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(picture)
	caption = text_label("", 14, MINT)
	detail.add_child(caption)
	landscape_label = text_label("", 18, MINT)
	detail.add_child(landscape_label)
	route_title = text_label("", 30)
	detail.add_child(route_title)
	facts = text_label("", 18, MINT)
	detail.add_child(facts)
	description = text_label("", 20)
	description.custom_minimum_size.y = 58
	detail.add_child(description)
	errors = RichTextLabel.new()
	errors.custom_minimum_size.y = 64
	errors.add_theme_font_size_override("normal_font_size", 16)
	errors.add_theme_color_override("default_color", Color("ffd2a4"))
	errors.selection_enabled = true
	layout.add_child(errors)
	footer = text_label("", 18, MINT)
	layout.add_child(footer)
	voice_status = text_label("", 16, MINT)
	voice_status.visible = false
	layout.add_child(voice_status)

func texture(path: String) -> Texture2D:
	if not textures.has(path):
		var img := Image.load_from_file(path)
		textures[path] = null if img == null or img.is_empty() else ImageTexture.create_from_image(img)
	return textures[path]

func render(value, left_key: String, right_key: String, speech_status: String = "") -> void:
	session = value
	voice_status.visible = session.control_mode == "voice"
	voice_status.text = speech_status
	if voice_status.visible and not session.voice_enabled:
		voice_status.text += " Prüfe die Steuerung unter Einstellungen."
	var entries: Array[String] = session.entries()
	if entries != previous_entries or session.routes != previous_routes:
		for button in buttons:
			routes_column.remove_child(button)
			button.queue_free()
		buttons.clear()
		for i in range(entries.size()):
			var button := Button.new()
			button.text = entries[i]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.focus_mode = Control.FOCUS_NONE
			button.custom_minimum_size.y = 52
			button.add_theme_font_size_override("font_size", 20)
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			if i < session.routes.size():
				button.icon = texture(session.routes[i].preview)
				button.expand_icon = true
				button.add_theme_constant_override("icon_max_width", 92)
				button.add_theme_constant_override("h_separation", 14)
				button.custom_minimum_size.y = 84
			button.add_theme_stylebox_override("hover", box_style(Color("bfe8d8")))
			button.add_theme_color_override("font_hover_color", INK)
			button.pressed.connect(func(): selected.emit(i))
			button.mouse_entered.connect(func(): session.menu_index = i)
			routes_column.add_child(button)
			buttons.append(button)
		previous_entries = entries.duplicate()
		previous_routes = session.routes.duplicate(true)
		previous_index = -1
	errors.visible = not session.catalog_errors.is_empty()
	errors.text = "Dateien prüfen:\n" + "\n".join(session.catalog_errors)
	footer.text = "[ %s ] Nächster Eintrag     [ %s ] Auswählen     ·     Du kannst auch klicken." % [left_key, right_key]
	if session.voice_enabled: footer.text += "\nSprache: next · select"
	if previous_index == session.menu_index: return
	previous_index = session.menu_index
	for i in range(buttons.size()):
		buttons[i].add_theme_stylebox_override("normal", box_style(MINT if i == previous_index else Color("294553")))
		buttons[i].add_theme_color_override("font_color", INK if i == previous_index else PAPER)
	if previous_index >= 0 and previous_index < buttons.size():
		scroll.ensure_control_visible.call_deferred(buttons[previous_index])
	if previous_index < session.routes.size():
		var route: Dictionary = session.routes[previous_index]
		picture.texture = texture(route.preview)
		route_title.text = route.name
		landscape_label.text = Scenarios.NAMES[route.scenario]
		facts.text = "%d m   ·   %d Kurven   ·   %d Sprünge" % [route.length_m, route.curves, route.jumps]
		description.text = route.description
		caption.text = "Landschaftsvorschau" if route.landscape_preview else "Blick auf die Strecke"
	else:
		picture.texture = texture(Scenarios.preview(session.model.track.scenario))
		landscape_label.text = ""
		route_title.text = "Keine gültige Strecke" if session.routes.is_empty() else entries[previous_index]
		facts.text = ""
		caption.text = "Landschaftsvorschau"
		description.text = "Lege eine gültige JSON-Datei in den Ordner tracks. Starte das Spiel danach neu." if session.routes.is_empty() else ("Ändere die Steuerung, die Tasten und die Hinweise." if previous_index == session.routes.size() else "Das Spiel schließen.")
