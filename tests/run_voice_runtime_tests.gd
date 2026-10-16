extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func _initialize() -> void:
    var runtime = load("res://scripts/input/voice_runtime.gd")
    check(runtime != null, "The voice runtime exists.")
    if runtime == null:
        quit(1)
        return
    var windows: Dictionary = runtime.command_for("Windows", false, "C:/Test Game/Stuntcar.exe", "res://")
    check(windows.executable == "C:/Test Game/voice/stuntcar-voice.exe", "The portable helper starts beside the game.")
    check(windows.arguments.is_empty(), "The portable helper needs no external Python script.")
    var source: Dictionary = runtime.command_for("Windows", true, "C:/Godot/Godot.exe", "C:/My Project/")
    check(source.executable == "C:/My Project/.tools/voice-env/Scripts/python.exe", "The Windows editor uses the Windows environment.")
    check(source.arguments == PackedStringArray(["C:/My Project/voice/recognizer.py"]), "Paths with spaces stay in one argument.")
    var mac: Dictionary = runtime.command_for("macOS", true, "/Applications/Godot.app/Contents/MacOS/Godot", "/tmp/My Project/")
    check(mac.executable == "/tmp/My Project/.tools/voice-env/bin/python", "The Mac source launch stays available.")
    print("VOICE RUNTIME: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)
