extends Node

signal unavailable(message: String)
const COMMANDS := ["left", "right", "faster", "slower", "pause", "resume", "next", "select", "start"]
var server := TCPServer.new()
var peer: StreamPeerTCP
var child_pid := -1
var enabled := false
var is_ready := false
var authenticated := false
var token := ""
var epoch := 0
var last_seq := 0
var last_message_ms := 0
var started_ms := 0
var status_text := "Sprache aus"
var buffer := PackedByteArray()
var commands: Array[Dictionary] = []
var input_level := 0.0
var heard_text := ""
var feedback_state := "listening"
var device_name := ""
var feedback_ms := 0

func start() -> void:
	stop()
	var python := ProjectSettings.globalize_path("res://.tools/voice-env/bin/python")
	if not FileAccess.file_exists(python):
		fail("Sprache fehlt. Öffne Sprache einrichten.command.")
		return
	if server.listen(0, "127.0.0.1") != OK:
		fail("Die lokale Sprachverbindung konnte nicht starten.")
		return
	token = Crypto.new().generate_random_bytes(24).hex_encode()
	enabled = true
	started_ms = Time.get_ticks_msec()
	last_message_ms = started_ms
	status_text = "Sprache startet. Eine Mikrofonfreigabe kann nötig sein."
	child_pid = OS.create_process(python, PackedStringArray([
		ProjectSettings.globalize_path("res://voice/recognizer.py"),
		"--port", str(server.get_local_port()), "--token", token]))
	if child_pid < 0: fail("Das Sprachprogramm konnte nicht starten.")

func stop() -> void:
	if peer != null: peer.disconnect_from_host()
	peer = null
	server.stop()
	if child_pid > 0 and OS.is_process_running(child_pid): OS.kill(child_pid)
	child_pid = -1
	enabled = false
	is_ready = false
	authenticated = false
	last_seq = 0
	buffer.clear()
	commands.clear()
	epoch += 1
	status_text = "Sprache aus"
	input_level = 0.0
	heard_text = ""
	device_name = ""

func fail(message: String) -> void:
	stop()
	status_text = message
	unavailable.emit(message)

func invalidate() -> void:
	epoch += 1
	heard_text = ""
	feedback_state = "listening"
	commands.clear()
	if peer != null and authenticated:
		peer.put_data((JSON.stringify({"type":"context", "epoch":epoch}) + "\n").to_utf8_buffer())

func poll() -> void:
	if not enabled: return
	var now := Time.get_ticks_msec()
	if is_ready and now - last_message_ms > 3000:
		fail("Mikrofonverbindung unterbrochen. Die Fahrt wartet.")
		return
	if not is_ready and now - started_ms > 60000:
		fail("Das Mikrofon wurde nicht bereit. Prüfe die Mikrofonfreigabe.")
		return
	if peer == null and server.is_connection_available(): peer = server.take_connection()
	if peer != null:
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			fail("Mikrofonverbindung beendet. Die Fahrt wartet.")
			return
		var available := peer.get_available_bytes()
		if available > 0:
			var data := peer.get_partial_data(mini(available, 8192))
			if data[0] == OK: consume_bytes(data[1])
	if enabled and child_pid > 0 and not OS.is_process_running(child_pid):
		fail("Das Sprachprogramm wurde beendet. Die Fahrt wartet.")

func consume_bytes(data: PackedByteArray) -> void:
	if not enabled: return
	buffer.append_array(data)
	while buffer.has(10):
		var end := buffer.find(10)
		if end > 1024:
			fail("Ungültige Nachricht vom Sprachprogramm.")
			return
		var line := buffer.slice(0, end).get_string_from_utf8()
		buffer = buffer.slice(end + 1)
		var packet = JSON.parse_string(line)
		if typeof(packet) != TYPE_DICTIONARY:
			fail("Ungültige Nachricht vom Sprachprogramm.")
			return
		accept_packet(packet)
		if not enabled: return
	if buffer.size() > 1024: fail("Ungültige Nachricht vom Sprachprogramm.")

func accept_packet(packet: Dictionary) -> void:
	var seq = packet.get("seq", 0)
	if typeof(seq) not in [TYPE_INT, TYPE_FLOAT] or float(seq) != floorf(float(seq)) or seq <= last_seq: return
	last_seq = int(seq)
	if not authenticated:
		if packet.get("type") != "hello" or packet.get("token") != token:
			fail("Die Sprachverbindung konnte sich nicht anmelden.")
			return
		authenticated = true
		invalidate()
		return
	last_message_ms = Time.get_ticks_msec()
	match packet.get("type", ""):
		"ready":
			is_ready = true
			device_name = str(packet.get("device", "Standardmikrofon")).left(60)
			status_text = "Mikrofon aktiv · Deutsch und Englisch"
		"feedback":
			if not is_ready or packet.get("epoch", -1) != epoch: return
			var level = packet.get("level", 0.0)
			if typeof(level) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(level)):
				input_level = clampf(float(level), 0.0, 1.0)
			var heard := str(packet.get("heard", "")).left(70)
			var state := str(packet.get("state", "listening"))
			if not heard.is_empty() or Time.get_ticks_msec() - feedback_ms > 2000:
				heard_text = heard
				feedback_state = state
			if not heard.is_empty(): feedback_ms = Time.get_ticks_msec()
		"error": fail(str(packet.get("message", "Mikrofonfehler")))
		"command":
			if not is_ready or packet.get("epoch", -1) != epoch or packet.get("command", "") not in COMMANDS: return
			if commands.size() >= 16:
				fail("Zu viele Sprachbefehle. Bitte Sprache erneut einschalten.")
				return
			commands.append(packet)

func take_commands() -> Array[Dictionary]:
	var result := commands.duplicate()
	commands.clear()
	return result

func _exit_tree() -> void:
	stop()
