extends RefCounted

const ACTIONS := ["left", "right", "faster", "slower"]
const DEFAULTS := [KEY_A, KEY_D, KEY_W, KEY_S]
const ARROWS := [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]

static func action_for(code: int, bindings: Array[int]) -> String:
    # A saved or custom assignment takes priority over an arrow alias.
    var index := bindings.find(code)
    if index >= 0: return ACTIONS[index]
    index = ARROWS.find(code)
    return ACTIONS[index] if index >= 0 else ""

static func restored(config: ConfigFile) -> Array[int]:
    var result: Array[int] = []
    for i in range(ACTIONS.size()):
        var code = config.get_value("input", ACTIONS[i], DEFAULTS[i])
        if typeof(code) != TYPE_INT or code <= 0 or code == KEY_ESCAPE or code in result:
            for fallback in [DEFAULTS[i], ARROWS[i], KEY_J, KEY_L, KEY_I, KEY_K]:
                if fallback not in result:
                    code = fallback
                    break
        result.append(code)
    return result
