extends RefCounted

const ROOT := "res://assets/stuntcar_kit/"
const NAMES := {"forest": "I18N_SCENARIO_FOREST", "alpine": "I18N_SCENARIO_ALPINE", "canyon": "I18N_SCENARIO_CANYON", "coast": "I18N_SCENARIO_COAST"}
const GROUND := {"forest": "grass", "alpine": "snow_shadow", "canyon": "sand", "coast": "sea"}

static func preview(scenario: String) -> String:
	return ROOT + "previews/" + scenario + "_preview.png"
