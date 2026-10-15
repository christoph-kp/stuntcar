extends Control
# Ein echter Mikrofonpegel: links kleine Balken, rechts größere Balken.
var level := 0.0
var confirmed := false
var progress := 0.0
const MINT := Color("a9e2c8")
const INK := Color("142f3e")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_signal(value: float, complete: bool, captured: float) -> void:
	level = clampf(value, 0.0, 1.0) if is_finite(value) else 0.0
	confirmed = complete
	progress = clampf(captured, 0.0, 1.0)
	queue_redraw()

func lit_bars() -> int:
	return clampi(roundi(level * 12.0), 0, 12)

func _draw() -> void:
	var gap := 8.0
	var width := (size.x - gap * 11.0) / 12.0
	var baseline := size.y - 32.0
	for index in range(12):
		var height := lerpf(24.0, baseline - 8.0, float(index) / 11.0)
		var rect := Rect2(index * (width + gap), baseline - height, width, height)
		draw_rect(rect, Color("294553"))
		var fill := 1.0 if index < lit_bars() else 0.0
		if fill > 0.0: draw_rect(rect, MINT)
		draw_rect(rect, Color("a3beb9") if confirmed else Color("698d94"), false, 1.0)
	draw_line(Vector2(0, size.y - 10), Vector2(size.x, size.y - 10), Color("294553"), 4.0)
	draw_line(Vector2(0, size.y - 10), Vector2(size.x * progress, size.y - 10), MINT, 4.0)
