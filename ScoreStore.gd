extends RefCounted

const MAX_ENTRIES := 10
const MAX_NAME_LENGTH := 12
const MAX_SCORE := 2147483647

var scores: Array[Dictionary] = []
var path: String


func _init(save_path: String = "user://highscores.json") -> void:
	path = save_path


func clean_name(value: String) -> String:
	var result := ""
	for character in value.strip_edges().to_upper():
		if character.unicode_at(0) >= 32 and character.unicode_at(0) != 127:
			result += character
	result = result.strip_edges().left(MAX_NAME_LENGTH)
	return result if not result.is_empty() else "JUGADOR"


func load_scores() -> Error:
	scores.clear()
	if not FileAccess.file_exists(path):
		return OK
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return parse_error
	var data: Variant = json.data
	if not data is Dictionary or data.get("version") != 1 or not data.get("scores") is Array:
		return ERR_FILE_UNRECOGNIZED
	var valid: Array[Dictionary] = []
	for entry in data["scores"]:
		if not entry is Dictionary or not entry.get("name") is String:
			continue
		var points: Variant = entry.get("score")
		if not (points is int or points is float):
			continue
		if not is_finite(float(points)) or points < 0 or points > MAX_SCORE or float(points) != floorf(float(points)):
			continue
		valid.append({"name": clean_name(entry["name"]), "score": int(points)})
	scores = _rank(valid)
	return OK


func submit(player_name: String, points: int) -> Error:
	if points < 0 or points > MAX_SCORE:
		return ERR_INVALID_PARAMETER
	var candidates: Array[Dictionary] = scores.duplicate(true)
	candidates.append({"name": clean_name(player_name), "score": points})
	var ranked := _rank(candidates)
	# Escribir primero un temporal evita truncar el ranking anterior.
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version": 1, "scores": ranked}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path))
	if rename_error != OK:
		return rename_error
	scores = ranked
	return OK


func _rank(entries: Array[Dictionary]) -> Array[Dictionary]:
	var ranked: Array[Dictionary] = []
	for entry in entries:
		var index := 0
		# Los empates conservan primero la partida mas antigua.
		while index < ranked.size() and ranked[index]["score"] >= entry["score"]:
			index += 1
		ranked.insert(index, entry)
		if ranked.size() > MAX_ENTRIES:
			ranked.resize(MAX_ENTRIES)
	return ranked
