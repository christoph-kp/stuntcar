extends RefCounted

const ROOT := "res://assets/stuntcar_kit/"
const NAMES := {"forest": "Nebelwald", "alpine": "Alpenpass", "canyon": "Felsenschlucht", "coast": "Regenküste"}
const GROUND := {"forest": "grass", "alpine": "snow_shadow", "canyon": "sand", "coast": "sea"}

static func preview(scenario: String) -> String:
	return ROOT + "previews/" + scenario + "_preview.png"
