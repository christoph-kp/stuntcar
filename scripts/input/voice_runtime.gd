extends RefCounted

static func command_for(platform: String, editor: bool, game_executable: String, project_root: String) -> Dictionary:
    if platform == "Windows" and not editor:
        return {"executable": game_executable.get_base_dir().path_join("voice/stuntcar-voice.exe"), "arguments": PackedStringArray()}
    var python := ".tools/voice-env/Scripts/python.exe" if platform == "Windows" else ".tools/voice-env/bin/python"
    return {"executable": project_root.path_join(python), "arguments": PackedStringArray([project_root.path_join("voice/recognizer.py")])}
