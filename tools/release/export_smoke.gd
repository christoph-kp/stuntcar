extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    check(not OS.has_feature("editor"), "The test runs in the exported game.")
    check(not FileAccess.file_exists("res://.env"), "The package contains no local environment file.")
    var scene = load("res://scenes/main.tscn").instantiate()
    scene.settings_path = OS.get_cache_dir().path_join("stuntcar-package-check-%d.cfg" % OS.get_process_id())
    root.add_child(scene)
    scene.set_physics_process(false)
    scene.session.sound_enabled = false
    check(scene.session.catalog_errors.is_empty(), "The packaged track catalog has no resource errors.")
    check(scene.session.routes.size() == 4, "The package contains all four tracks.")
    for i in range(scene.session.routes.size()):
        scene.session.open_tracks()
        scene.session.activate(i)
        check(scene.track != null, "A packaged track loads.")
        check(not scene.session.routes[i].landscape_preview, "The package keeps the track-specific preview.")
        var image = scene.ui.track_selection.texture(scene.session.routes[i].preview)
        check(image != null and image.get_width() > 0, "The packaged preview loads.")
        scene.session.restart()
        scene._physics_process(1.0 / 60.0)
        check(scene.car != null and scene.model.distance_m > 5.0, "The car and track run in the package.")
        if i == 0:
            scene.sync_voice_context()
            var gas := InputEventKey.new()
            gas.physical_keycode = KEY_W
            gas.pressed = true
            scene._input(gas)
            var before: float = scene.model.speed_mps
            scene._physics_process(0.1)
            check(scene.model.speed_mps > before, "W accelerates in the exported game.")
            gas.pressed = false
            scene._input(gas)
            var brake := InputEventKey.new()
            brake.physical_keycode = KEY_S
            brake.pressed = true
            scene._input(brake)
            before = scene.model.speed_mps
            scene._physics_process(0.1)
            check(scene.model.speed_mps < before, "S brakes in the exported game.")
            brake.pressed = false
            scene._input(brake)
    scene.queue_free()
    for i in range(3):
        await process_frame
    print("PACKAGE CHECK: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)
