extends Node2D

# INVASORES PIXEL - un mini Space Invaders para Godot 4.
# Aliens animados y efectos dibujados con pixeles por codigo.

var W := 960.0
var H := 720.0
var SCREEN_H := 720.0
var TOUCH_LEFT := Rect2()
var TOUCH_RIGHT := Rect2()
var TOUCH_FIRE := Rect2()
var TOUCH_START := Rect2()
var PLAYER_Y := 645.0
var mobile := false
var portrait := false
var last_window_size := Vector2i.ZERO
const PLAYER_SPEED := 410.0
const SHOT_SPEED := 590.0
const ENEMY_SHOT_SPEED := 260.0
const NORMAL_SHOT_DELAY := 0.23
const RAPID_FIRE_DURATION := 10.0
const TRIPLE_FIRE_DURATION := 10.0
const PIERCING_DURATION := 10.0
const FIRST_POWER_DELAY := Vector2(20.0, 30.0)
const NEXT_POWER_DELAY := Vector2(30.0, 45.0)
const FIRST_BOMB_DELAY := Vector2(90.0, 150.0)
const NEXT_BOMB_DELAY := Vector2(120.0, 180.0)
const GAME_WIDTH := 540.0
const GAME_HEIGHT := 960.0
const FIELD_HEIGHT := 800.0
const BOSS_HEALTH := 50
const BOSS_SIZE := 168.0
const BOSS_SHOT_INTERVAL := 1.32
const ALIEN_FRAME_DURATION := 0.18
const BACKGROUND_DARKNESS := 0.55
const VIOLET := Color(0.76, 0.40, 1.0)
const SHIP_BLUE := Color(0.25, 0.52, 1.0)

const POWER_P := ["11110", "11011", "11011", "11110", "11000", "11000", "11000"]
const POWER_BOLT := [
	"000011110", "000111100", "001111000", "011110000",
	"111111110", "000111100", "001111000", "011110000", "011100000", "011000000", "010000000"
]
const BOMB_SPRITE := [
	"0000000000000", "0000000011000", "0000000110000",
	"0000001100000", "0000011100000", "0001111111000",
	"0011111111100", "0111111111110", "0111111111110",
	"1111111111111", "1111111111111", "0111111111110",
	"0011111111100", "0001111111000", "0000011100000"
]

const CYAN := Color(0.36, 0.92, 1.0)
const PINK := Color(1.0, 0.36, 0.66)
const GOLD := Color(1.0, 0.82, 0.35)
const GREEN := Color(0.44, 1.0, 0.62)
const WHITE := Color(0.93, 0.95, 1.0)
const DARK := Color(0.035, 0.045, 0.09)
const UNIVERSE_BACKGROUND := preload("res://assets/aliens/alienfondo.png")
const ARCADE_FONT: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")
const START_LOGO: Texture2D = preload("res://assets/1-blanco.png")
const MUSIC: AudioStreamWAV = preload("res://assets/audio/NN.wav")
const ALIEN_SHOT_SOUND: AudioStream = preload("res://assets/audio/alien_shot.wav")
const ALIEN_EXPLOSION_SOUND: AudioStream = preload("res://assets/audio/alien_explosion.wav")
const POWER_PICKUP_SOUND: AudioStream = preload("res://assets/audio/power_pickup.wav")
const BOMB_SOUND: AudioStream = preload("res://assets/audio/bomb_explosion.wav")
const OnlineScoreService = preload("res://OnlineScores.gd")

const PLAYER_SPRITE := [
	"0000001000000",
	"0000011100000",
	"0000111110000",
	"0111111111110",
	"1111111111111",
	"1111111111111",
    "1110000000111"
]

const PLAYER_DOUBLE_SPRITE := [
	"00001000000010000",
	"00011100000111000",
	"00011100000111000",
	"00111110001111100",
	"01111111011111110",
	"11111111111111111",
	"11111111111111111",
	"11101111111110111",
	"11000111011100011"
]

const PLAYER_TRIPLE_SPRITE := [
	"0001000001000001000",
	"0011100011100011100",
	"0011100111110011100",
	"0111111111111111110",
	"1111111111111111111",
	"1111111111111111111",
	"1111011111111101111",
	"1110011111111100111",
	"1100001110111000011",
	"1000001100011000001"
]

const ALIEN_HEAD := [
	"0000111110000", "0011111111100", "0111111111110",
	"1110011100111", "1110001000111", "1111010101111", "0111111111110"
]
const ALIEN_LEGS := [
	["0011101011100", "0110001000110", "1100010100011", "0100100010010"],
	["0011101011100", "0011001001100", "0001101011000", "0011001001100"],
	["0011101011100", "0010010100100", "0110100010110", "1101000001011"]
]

var mode := "menu"  # menu, playing, paused, game_over
var score := 0
var lives := 3
var wave := 1
var player_x := W / 2.0
var shot_delay := 0.0
var enemy_shot_delay := 1.0
var invulnerable := 0.0
var enemy_direction := 1.0
var clock := 0.0
var alien_animation_clock := 0.0
var alien_rows: Array[Dictionary] = []
var power_ups: Array[Dictionary] = []
var power_drop_delay := 0.0
var bomb_drop_delay := 0.0
var life_drop_delay := 0.0
var bomb_flash := 0.0
var bomb_wave_delay := 0.0
var shield_active := false
var shield_flash := 0.0
var rapid_fire_left := 0.0
var piercing_left := 0.0
var next_alien_id := 0
var dual_cannons := false
var triple_fire_left := 0.0
var power_message := ""
var power_message_left := 0.0

var aliens: Array = []
var player_shots: Array = []
var enemy_shots: Array = []
var barriers: Array = []
var particles: Array = []
var stars: Array = []
var touch_actions: Dictionary = {}
var music_player: AudioStreamPlayer
var application_in_background := false
var alien_shot_player: AudioStreamPlayer
var alien_explosion_player: AudioStreamPlayer
var power_pickup_player: AudioStreamPlayer
var bomb_player: AudioStreamPlayer
var online_scores: OnlineScoreService
var score_submitted := false
var score_saving := false
var current_run_id := ""
var submitted_name := ""
var game_over_panel: PanelContainer
var game_over_scroll: ScrollContainer
var name_input: LineEdit
var save_score_button: Button
var restart_button: Button
var ranking_status: Label
var ranking_connection: Label
var refresh_ranking_button: Button
var ranking_rows: Array[Label] = []


func _ready() -> void:
	randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup_audio()
	online_scores = OnlineScoreService.new()
	add_child(online_scores)
	online_scores.scores_loaded.connect(_on_ranking_loaded)
	online_scores.score_saved.connect(_on_score_saved)
	_setup_game_over_screen()
	mobile = _is_mobile_device()
	_setup_web_keyboard_focus()
	get_window().size_changed.connect(_update_layout)
	_update_layout()
	for i in range(85):
		stars.append({
			"p": Vector2(randf_range(0.0, W), randf_range(65.0, H)),
			"r": randf_range(0.6, 1.8),
			"phase": randf_range(0.0, TAU)
		})


func _setup_game_over_screen() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	game_over_panel = PanelContainer.new()
	game_over_panel.visible = false
	var theme := Theme.new()
	theme.default_font = ARCADE_FONT
	theme.default_font_size = 16
	game_over_panel.theme = theme
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.025, 0.075, 0.97)
	panel_style.border_color = CYAN
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(18)
	game_over_panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(game_over_panel)
	var scroll := ScrollContainer.new()
	game_over_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	game_over_panel.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var title := _ranking_label("GAME OVER", GOLD, 32)
	content.add_child(title)
	var final_score := _ranking_label("", CYAN, 16)
	final_score.name = "FinalScore"
	content.add_child(final_score)
	content.add_child(_ranking_label("TU NOMBRE (12 CARACTERES)", WHITE, 16))
	name_input = LineEdit.new()
	name_input.max_length = 12
	name_input.placeholder_text = "JUGADOR"
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.custom_minimum_size.y = 56
	name_input.virtual_keyboard_enabled = true
	name_input.text_submitted.connect(_submit_score)
	content.add_child(name_input)
	save_score_button = _ranking_button("GUARDAR PUNTAJE")
	save_score_button.pressed.connect(func() -> void: _submit_score(name_input.text))
	content.add_child(save_score_button)
	ranking_status = _ranking_label("", GREEN, 16)
	ranking_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(ranking_status)
	content.add_child(_ranking_label("TOP 10 MUNDIAL", GOLD, 24))
	ranking_connection = _ranking_label("", WHITE, 8)
	ranking_connection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(ranking_connection)
	for index in range(10):
		var row := _ranking_label("", WHITE, 16)
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		content.add_child(row)
		ranking_rows.append(row)
	refresh_ranking_button = _ranking_button("ACTUALIZAR RANKING")
	refresh_ranking_button.pressed.connect(_refresh_ranking)
	content.add_child(refresh_ranking_button)
	restart_button = _ranking_button("VOLVER A JUGAR")
	restart_button.pressed.connect(_start_game)
	content.add_child(restart_button)
	content.add_child(_ranking_label("PUNTAJES COMPARTIDOS ONLINE", Color(0.6, 0.65, 0.8), 8))
	_update_ranking_rows()


func _ranking_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _ranking_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.add_theme_color_override("font_color", CYAN)
	return button


func _layout_game_over_screen() -> void:
	if not is_instance_valid(game_over_panel):
		return
	var panel_width := minf(W - 32.0, 760.0)
	game_over_panel.position = Vector2((W - panel_width) / 2.0, 16)
	game_over_panel.size = Vector2(panel_width, SCREEN_H - 32)


func _finish_game() -> void:
	if mode == "game_over":
		return
	mode = "game_over"
	power_ups.clear()
	shield_active = false
	rapid_fire_left = 0.0
	piercing_left = 0.0
	dual_cannons = false
	triple_fire_left = 0.0
	touch_actions.clear()
	score_submitted = false
	score_saving = false
	submitted_name = ""
	name_input.editable = true
	name_input.text = ""
	save_score_button.disabled = false
	save_score_button.text = "GUARDAR PUNTAJE"
	restart_button.disabled = false
	var final_score: Label = game_over_panel.find_child("FinalScore", true, false) as Label
	final_score.text = "PUNTUACION: %d" % score
	ranking_status.text = "INGRESA TU NOMBRE Y GUARDA"
	_update_ranking_rows()
	game_over_panel.show()
	game_over_scroll.scroll_vertical = 0
	_layout_game_over_screen()
	_refresh_ranking()
	# En Web el input HTML intenta enfocar al mostrarse y tambien al tocarlo.
	if mobile and not OS.has_feature("web"):
		_focus_native_player_name.call_deferred()
	elif not mobile:
		name_input.call_deferred("grab_focus")


func _focus_native_player_name() -> void:
	if mode == "game_over" and name_input.editable:
		name_input.grab_focus()
		DisplayServer.virtual_keyboard_show(name_input.text)


func _submit_score(player_name: String) -> void:
	if mode != "game_over" or score_submitted or score_saving:
		return
	if mobile and OS.has_feature("web") and submitted_name.is_empty():
		var browser_name: Variant = JavaScriptBridge.eval("window.PixelNameInput ? window.PixelNameInput.getValue() : null")
		if browser_name is String:
			player_name = browser_name
	# Conservar nombre + id en todos los reintentos, incluso tras un timeout.
	if submitted_name.is_empty():
		submitted_name = online_scores.clean_name(player_name)
	name_input.text = submitted_name
	name_input.editable = false
	_hide_mobile_name_input()
	score_saving = true
	save_score_button.disabled = true
	ranking_status.text = "GUARDANDO ONLINE..."
	online_scores.submit(submitted_name, score, current_run_id)


func _on_score_saved(success: bool, entry: Dictionary, message: String) -> void:
	if mode != "game_over" or entry.get("id") != current_run_id:
		return
	score_saving = false
	ranking_status.text = message
	if not success:
		save_score_button.disabled = false
		save_score_button.text = "REINTENTAR GUARDADO"
		return
	score_submitted = true
	name_input.release_focus()
	DisplayServer.virtual_keyboard_hide()
	save_score_button.disabled = true
	restart_button.disabled = false
	_refresh_ranking()
	if not mobile:
		restart_button.call_deferred("grab_focus")


func _refresh_ranking() -> void:
	ranking_connection.text = "CARGANDO RANKING MUNDIAL..."
	refresh_ranking_button.disabled = true
	online_scores.load_scores()


func _on_ranking_loaded(success: bool, message: String) -> void:
	if mode != "game_over":
		return
	refresh_ranking_button.disabled = false
	ranking_connection.text = "EN VIVO - TU PARTIDA SE MARCA EN VERDE" if success else message
	if not success and not online_scores.scores.is_empty():
		ranking_connection.text += " (ULTIMA LECTURA)"
	_update_ranking_rows()


func _update_ranking_rows() -> void:
	for index in range(ranking_rows.size()):
		var row: Label = ranking_rows[index]
		row.text = " %02d. ------------  ------" % (index + 1)
		var is_current := false
		if index < online_scores.scores.size():
			var entry: Dictionary = online_scores.scores[index]
			is_current = score_submitted and entry["id"] == current_run_id
			row.text = "%s%02d. %-12s %07d" % [">" if is_current else " ", index + 1, entry["name"], int(entry["score"])]
			row.tooltip_text = "FECHA UTC: " + str(entry["date"])
		row.add_theme_color_override("font_color", GREEN if is_current else (GOLD if index == 0 else WHITE))


func _setup_audio() -> void:
	# Copia mutable: configurar el bucle sin modificar el recurso constante.
	var looping_music: AudioStreamWAV = MUSIC.duplicate() as AudioStreamWAV
	looping_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	looping_music.loop_begin = 0
	looping_music.loop_end = int(looping_music.get_length() * looping_music.mix_rate)
	music_player = _create_audio_player("Music", looping_music, -16.0, 1)
	alien_shot_player = _create_audio_player("AlienShot", ALIEN_SHOT_SOUND, -22.0, 2)
	alien_explosion_player = _create_audio_player("AlienExplosion", ALIEN_EXPLOSION_SOUND, -17.0, 4)
	power_pickup_player = _create_audio_player("PowerPickup", POWER_PICKUP_SOUND, -17.0, 2)
	bomb_player = _create_audio_player("Bomb", BOMB_SOUND, -13.0, 1)
	_ensure_music_playing()


func _create_audio_player(player_name: String, stream: AudioStream, volume: float, voices: int) -> AudioStreamPlayer:
	var audio_player := AudioStreamPlayer.new()
	audio_player.name = player_name
	audio_player.stream = stream
	audio_player.volume_db = volume
	audio_player.max_polyphony = voices
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio_player)
	return audio_player


func _ensure_music_playing() -> void:
	# La musica no se reinicia al comenzar, pausar, morir ni cambiar de oleada.
	if application_in_background:
		return
	if is_instance_valid(music_player) and not music_player.playing:
		music_player.play()


func _is_mobile_device() -> bool:
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if OS.has_feature("web"):
		# Incluye iPadOS cuando el navegador se identifica como una Mac.
		return JavaScriptBridge.eval("/Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)") == true
	# Una PC con pantalla tactil sigue usando el formato de escritorio.
	return false


func _setup_web_keyboard_focus() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
		(() => {
			const canvas = document.getElementById('canvas');
			if (!canvas) return;
			canvas.tabIndex = 0;
			if (!canvas.dataset.gameKeyboardFocus) {
				canvas.addEventListener('pointerdown', () => canvas.focus({preventScroll: true}));
				canvas.dataset.gameKeyboardFocus = 'true';
			}
			canvas.focus({preventScroll: true});
		})();
	""")


func _update_layout() -> void:
	var window_size := get_window().size
	if window_size.x <= 0 or window_size.y <= 0 or window_size == last_window_size:
		return
	last_window_size = window_size
	var old_size := Vector2(W, H)
	# Mismo campo 9:16 en todos los dispositivos: solo cambia la escala.
	portrait = true
	W = GAME_WIDTH
	SCREEN_H = GAME_HEIGHT
	H = FIELD_HEIGHT
	PLAYER_Y = H - 75.0
	# Una misma escala en ambos ejes: los sprites no se deforman.
	get_window().content_scale_size = Vector2i(int(W), int(SCREEN_H))
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	touch_actions.clear()
	_layout_touch_controls()
	_remap_game(old_size)
	_layout_game_over_screen()
	queue_redraw()


func _layout_touch_controls() -> void:
	TOUCH_LEFT = Rect2(12, H + 12, 142, 136)
	TOUCH_RIGHT = Rect2(166, H + 12, 142, 136)
	TOUCH_FIRE = Rect2(326, H + 12, 202, 136)
	TOUCH_START = Rect2(24, H / 2.0 - 40, W - 48, 150)


func _remap_position(point: Vector2, old_size: Vector2) -> Vector2:
	return Vector2(point.x * W / old_size.x, 77.0 + (point.y - 77.0) * (H - 77.0) / (old_size.y - 77.0))


func _remap_game(old_size: Vector2) -> void:
	# Girar el telefono conserva enemigos, vidas, puntuacion y barreras.
	player_x = clampf(player_x * W / old_size.x, _player_margin(), W - _player_margin())
	for collection in [aliens, barriers, particles, stars, power_ups]:
		for item in collection:
			item["p"] = _remap_position(item["p"], old_size)
	for collection in [player_shots, enemy_shots]:
		for i in range(collection.size()):
			if collection[i] is Dictionary:
				collection[i]["p"] = _remap_position(collection[i]["p"], old_size)
			else:
				collection[i] = _remap_position(collection[i], old_size)


func _handle_keyboard(event: InputEventKey) -> void:
	if not event.pressed or event.echo:
		return
	var key := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if mode == "menu":
		if key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE:
			_start_game()
			get_viewport().set_input_as_handled()
	elif key == KEY_P or (mode == "paused" and (key == KEY_ENTER or key == KEY_SPACE)):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		application_in_background = true
		if is_instance_valid(music_player):
			music_player.stream_paused = true
		touch_actions.clear()
		if mode == "playing":
			mode = "paused"
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		application_in_background = false
		if is_instance_valid(music_player):
			music_player.stream_paused = false
			_ensure_music_playing()


func _toggle_pause() -> void:
	touch_actions.clear()
	if mode == "playing":
		mode = "paused"
	elif mode == "paused":
		mode = "playing"


func _input(event: InputEvent) -> void:
	# En Web el navegador habilita el audio tras la primera interaccion.
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_ensure_music_playing()
	# LineEdit y botones reciben texto, ENTER y toques sin activar el juego.
	if mode == "game_over":
		return
	# Recibir el teclado antes de que un Control con foco consuma ENTER/ESPACIO.
	if event is InputEventKey:
		_handle_keyboard(event)
		return
	# Cada dedo conserva su propia accion: mover y disparar a la vez.
	if event is InputEventScreenTouch:
		if not mobile:
			mobile = true
			last_window_size = Vector2i.ZERO
			_update_layout()
		if event.pressed and not event.canceled:
			_press_touch(event.index, _touch_position(event.position))
		else:
			touch_actions.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if touch_actions.has(event.index):
			touch_actions[event.index] = _touch_action(_touch_position(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not mobile and mode == "paused":
				_toggle_pause()
				return
			_press_touch(-1, _touch_position(event.position))
		else:
			touch_actions.erase(-1)
	elif event is InputEventMouseMotion and touch_actions.has(-1):
		touch_actions[-1] = _touch_action(_touch_position(event.position))


func _touch_position(position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * position


func _touch_action(position: Vector2) -> String:
	if mobile and mode == "playing":
		if TOUCH_LEFT.has_point(position):
			return "left"
		if TOUCH_RIGHT.has_point(position):
			return "right"
		if TOUCH_FIRE.has_point(position):
			return "fire"
	return ""


func _press_touch(index: int, position: Vector2) -> void:
	if mode == "menu" and TOUCH_START.has_point(position):
		_start_game()
	elif mode == "paused" and TOUCH_START.has_point(position):
		_toggle_pause()
	else:
		touch_actions[index] = _touch_action(position)


func _start_game() -> void:
	_hide_mobile_name_input()
	online_scores.cancel_pending()
	current_run_id = online_scores.new_run_id()
	game_over_panel.hide()
	name_input.release_focus()
	DisplayServer.virtual_keyboard_hide()
	touch_actions.clear()
	score = 0
	lives = 3
	wave = 1
	player_x = W / 2.0
	player_shots.clear()
	enemy_shots.clear()
	particles.clear()
	barriers.clear()
	shot_delay = 0.0
	invulnerable = 0.0
	alien_animation_clock = 0.0
	power_ups.clear()
	power_drop_delay = randf_range(FIRST_POWER_DELAY.x, FIRST_POWER_DELAY.y)
	bomb_drop_delay = randf_range(FIRST_BOMB_DELAY.x, FIRST_BOMB_DELAY.y)
	life_drop_delay = randf_range(FIRST_BOMB_DELAY.x, FIRST_BOMB_DELAY.y)
	bomb_flash = 0.0
	bomb_wave_delay = 0.0
	shield_active = false
	shield_flash = 0.0
	rapid_fire_left = 0.0
	piercing_left = 0.0
	dual_cannons = false
	triple_fire_left = 0.0
	power_message = ""
	power_message_left = 0.0
	_create_barriers()
	_spawn_wave()
	mode = "playing"


func _spawn_wave() -> void:
	aliens.clear()
	alien_rows.clear()
	player_shots.clear()
	enemy_shots.clear()
	enemy_direction = 1.0
	enemy_shot_delay = 1.25
	if wave % 10 == 0:
		next_alien_id += 1
		aliens.append({"id": next_alien_id, "p": Vector2(W / 2.0, 205.0), "kind": posmod(int(wave / 10) - 1, 3), "col": 0, "boss": true, "hp": BOSS_HEALTH, "flash": 0.0})
		enemy_shot_delay = BOSS_SHOT_INTERVAL
		return
	var speed_slots := [0, 1, 2, 3]
	speed_slots.shuffle()
	var first_direction := -1.0 if randf() < 0.5 else 1.0
	var base_speed := 28.0 + minf((wave - 1) * 2.0, 72.0)
	for row in range(4):
		alien_rows.append({
			"speed": base_speed + speed_slots[row] * 5.0 + randf_range(0.0, 3.0),
			"direction": first_direction if row % 2 == 0 else -first_direction
		})
		for col in range(10):
			next_alien_id += 1
			aliens.append({
				"id": next_alien_id,
				"p": Vector2(W * 0.15 + col * W * 0.077, 132.0 + row * 56.0),
				# Una fila fucsia, una verde agua y dos azules.
				"kind": mini(row, 2),
				"row": row,
				"col": col
			})


func _create_barriers() -> void:
	barriers.clear()
	var bunker_count := 3 if portrait else 4
	for bunker in range(bunker_count):
		var bx := W * (bunker + 0.5) / bunker_count - 45.0
		for row in range(3):
			for col in range(7):
				if row == 2 and col >= 2 and col <= 4:
					continue
				barriers.append({"p": Vector2(bx + col * 15.0, H - 179.0 + row * 14.0), "hp": 2})


func _process(delta: float) -> void:
	_sync_mobile_name_input()
	clock += delta
	_update_particles(delta)

	if mode == "playing":
		alien_animation_clock += delta
		_update_game(delta)

	queue_redraw()


func _hide_mobile_name_input() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.PixelNameInput) window.PixelNameInput.hide();")


func _sync_mobile_name_input() -> void:
	if not mobile or not OS.has_feature("web"):
		return
	var rect := name_input.get_global_rect()
	var shown := mode == "game_over" and name_input.editable and game_over_scroll.get_global_rect().encloses(rect)
	var state := {"session": current_run_id, "value": name_input.text, "visible": shown, "x": rect.position.x, "y": rect.position.y, "w": rect.size.x, "h": rect.size.y, "width": W, "height": SCREEN_H}
	var response: Variant = JavaScriptBridge.eval("window.PixelNameInput ? JSON.stringify(window.PixelNameInput.update(%s)) : null" % JSON.stringify(state))
	if not response is String:
		return
	var parsed: Variant = JSON.parse_string(response)
	if parsed is Dictionary and parsed.get("value") is String:
		name_input.text = str(parsed["value"]).left(12)
		if parsed.get("submitted", false):
			_submit_score(name_input.text)


func _update_game(delta: float) -> void:
	shot_delay = maxf(0.0, shot_delay - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	_update_player_bonuses(delta)
	bomb_flash = maxf(0.0, bomb_flash - delta)
	bomb_wave_delay = maxf(0.0, bomb_wave_delay - delta)
	enemy_shot_delay -= delta

	var axis := 0.0
	if _key_down(KEY_LEFT) or _key_down(KEY_A) or touch_actions.values().has("left"):
		axis -= 1.0
	if _key_down(KEY_RIGHT) or _key_down(KEY_D) or touch_actions.values().has("right"):
		axis += 1.0
	player_x = clampf(player_x + axis * PLAYER_SPEED * delta, _player_margin(), W - _player_margin())

	if (_key_down(KEY_SPACE) or touch_actions.values().has("fire")) and shot_delay <= 0.0:
		_fire_player_shots()
		shot_delay = NORMAL_SHOT_DELAY * (0.5 if rapid_fire_left > 0.0 else 1.0)

	_move_aliens(delta)
	if mode != "playing":
		return
	_update_power_ups(delta)

	if enemy_shot_delay <= 0.0 and not aliens.is_empty():
		_enemy_volley()

	_update_player_shots(delta)
	_update_enemy_shots(delta)
	if mode != "playing":
		return

	if aliens.is_empty() and bomb_wave_delay <= 0.0:
		wave += 1
		_spawn_wave()


func _key_down(key: Key) -> bool:
	return Input.is_physical_key_pressed(key) or Input.is_key_pressed(key)


func _enemy_volley() -> void:
	if aliens.is_empty():
		return
	var shooter: Dictionary = aliens.pick_random()
	if shooter.get("boss", false):
		for offset in [-54.0, 0.0, 54.0]:
			enemy_shots.append(shooter["p"] + Vector2(offset, BOSS_SIZE * 0.40))
		enemy_shot_delay = BOSS_SHOT_INTERVAL
	else:
		for alien in aliens:
			if alien["col"] == shooter["col"] and alien["p"].y > shooter["p"].y:
				shooter = alien
		enemy_shots.append(shooter["p"] + Vector2(0, 23))
		enemy_shot_delay = maxf(0.36, 1.15 - wave * 0.07) * randf_range(0.75, 1.35)
	alien_shot_player.play()


func _enemy_bullet_speed() -> float:
	return ENEMY_SHOT_SPEED + wave * 14.0


func _update_player_bonuses(delta: float) -> void:
	rapid_fire_left = maxf(0.0, rapid_fire_left - delta)
	piercing_left = maxf(0.0, piercing_left - delta)
	shield_flash = maxf(0.0, shield_flash - delta)
	power_message_left = maxf(0.0, power_message_left - delta)
	var had_triple := triple_fire_left > 0.0
	triple_fire_left = maxf(0.0, triple_fire_left - delta)
	if had_triple and triple_fire_left == 0.0:
		power_message = "VOLVISTE A DOBLE CAÑÓN"
		power_message_left = 2.5


func _player_cannon_count() -> int:
	if triple_fire_left > 0.0:
		return 3
	return 2 if dual_cannons else 1


func _player_color() -> Color:
	match _player_cannon_count():
		3: return VIOLET
		2: return SHIP_BLUE
	return CYAN


func _player_margin() -> float:
	match _player_cannon_count():
		3: return 52.0
		2: return 47.0
	return 38.0


func _player_hit_half_width() -> float:
	match _player_cannon_count():
		3: return 41.0
		2: return 35.0
	return 25.0


func _shield_width_scale() -> float:
	return 1.35 if _player_cannon_count() == 3 else (1.2 if dual_cannons else 1.0)


func _fire_player_shots() -> void:
	# Los disparos nacen en cada pico real del sprite, no en un cañon central.
	var offsets: Array[float] = [0.0]
	var muzzle_y := PLAYER_Y - 28.0
	match _player_cannon_count():
		2:
			offsets = [-20.0, 20.0]
			muzzle_y = PLAYER_Y - 29.0
		3:
			offsets = [-30.0, 0.0, 30.0]
			muzzle_y = PLAYER_Y - 32.0
	for offset in offsets:
		player_shots.append({"p": Vector2(player_x + offset, muzzle_y), "hit_ids": {}})


func _power_up_kind(roll: float) -> String:
	if roll < 0.225:
		return "shield"
	if roll < 0.450:
		return "rapid"
	if roll < 0.675:
		return "weapon"
	if roll < 0.900:
		return "piercing"
	return "repair"


func _update_power_ups(delta: float) -> void:
	# Al vencer el intervalo queda listo hasta la proxima baja del jugador.
	power_drop_delay = maxf(0.0, power_drop_delay - delta)
	bomb_drop_delay = maxf(0.0, bomb_drop_delay - delta)
	life_drop_delay = maxf(0.0, life_drop_delay - delta)
	for index in range(power_ups.size() - 1, -1, -1):
		var item: Dictionary = power_ups[index]
		var previous_y: float = item["p"].y
		var is_bomb: bool = item["kind"] == "bomb"
		item["p"].y += _enemy_bullet_speed() * (0.6 if is_bomb else 0.5) * delta
		# Barrido vertical: tampoco se pierde la recogida si cae un frame largo.
		if absf(item["p"].x - player_x) < (56.0 if is_bomb else 48.0) and previous_y <= PLAYER_Y + 34.0 and item["p"].y >= PLAYER_Y - 34.0:
			power_ups.remove_at(index)
			_apply_power_up(item["kind"])
			if not is_bomb:
				power_pickup_player.play()
		elif item["p"].y > H + 30.0:
			power_ups.remove_at(index)


func _try_drop_power_up(at: Vector2) -> void:
	if power_drop_delay > 0.0:
		return
	power_ups.append({
		"p": at,
		"kind": _power_up_kind(randf()),
		"phase": randf_range(0.0, TAU)
	})
	_explode(at, GOLD)
	# Reiniciar solo al soltarlo: varias bajas juntas no multiplican el bonus.
	power_drop_delay = randf_range(NEXT_POWER_DELAY.x, NEXT_POWER_DELAY.y)


func _apply_power_up(kind: String) -> void:
	match kind:
		"bomb":
			_detonate_bomb()
		"life":
			lives += 1
			power_message = "1UP - VIDA EXTRA"
			_explode(Vector2(player_x, PLAYER_Y), GREEN)
		"piercing":
			piercing_left = PIERCING_DURATION
			power_message = "RAYOS PERFORANTES POR 10 SEGUNDOS"
			_explode(Vector2(player_x, PLAYER_Y), CYAN)
		"shield":
			# Protege de un impacto frontal. Recoger otro lo recarga, no acumula.
			if shield_active:
				return
			shield_active = true
			power_message = "ESCUDO FRONTAL LISTO"
			_explode(Vector2(player_x, PLAYER_Y - 30.0), VIOLET)
		"rapid":
			# Repetir el mismo bonus renueva los diez segundos.
			rapid_fire_left = RAPID_FIRE_DURATION
			shot_delay = minf(shot_delay, NORMAL_SHOT_DELAY * 0.5)
			power_message = "FUEGO X2 DURANTE 10 SEGUNDOS"
			_explode(Vector2(player_x, PLAYER_Y), GOLD)
		"weapon":
			if dual_cannons:
				triple_fire_left = TRIPLE_FIRE_DURATION
				power_message = "TRIPLE CAÑÓN DURANTE 10 SEGUNDOS"
			else:
				dual_cannons = true
				power_message = "DOBLE CAÑÓN ACTIVADO"
			player_x = clampf(player_x, _player_margin(), W - _player_margin())
			_explode(Vector2(player_x, PLAYER_Y), _player_color())
		"repair":
			_create_barriers()
			power_message = "BARRERAS RESTAURADAS"
			var bunker_count := 3 if portrait else 4
			for bunker in range(bunker_count):
				_explode(Vector2(W * (bunker + 0.5) / bunker_count, H - 160.0), GREEN)
	power_message_left = 2.5


func _try_drop_bomb(at: Vector2) -> void:
	if bomb_drop_delay > 0.0:
		return
	power_ups.append({"p": at, "kind": "bomb", "phase": randf_range(0.0, TAU)})
	bomb_drop_delay = randf_range(NEXT_BOMB_DELAY.x, NEXT_BOMB_DELAY.y)


func _defeat_alien(index: int, play_sound: bool = true, drop_bomb: bool = true) -> void:
	var alien: Dictionary = aliens[index]
	score += (1500 + int(wave / 10) * 500) if alien.get("boss", false) else (3 - alien["kind"]) * 10
	_explode(alien["p"], _alien_color(alien["kind"]))
	_try_drop_power_up(alien["p"])
	if drop_bomb:
		_try_drop_bomb(alien["p"])
		_try_drop_life(alien["p"])
	aliens.remove_at(index)
	if play_sound:
		alien_explosion_player.play()


func _try_drop_life(at: Vector2) -> void:
	# Temporizador propio: puede coincidir con una bomba en la misma baja.
	if life_drop_delay > 0.0:
		return
	var side := 62.0 if at.x <= W - 90.0 else -62.0
	var position := Vector2(clampf(at.x + side, 35.0, W - 35.0), at.y)
	power_ups.append({"p": position, "kind": "life", "phase": randf_range(0.0, TAU)})
	life_drop_delay = randf_range(NEXT_BOMB_DELAY.x, NEXT_BOMB_DELAY.y)


func _detonate_bomb() -> void:
	# Compartir la misma baja garantiza los puntos y las P pendientes.
	for index in range(aliens.size() - 1, -1, -1):
		_defeat_alien(index, false, false)
	enemy_shots.clear()
	player_shots.clear()
	bomb_flash = 0.5
	bomb_wave_delay = 0.6
	bomb_player.play()
	power_message = "BOMBA: INVASORES ELIMINADOS"


func _move_aliens(delta: float) -> void:
	if not aliens.is_empty() and aliens[0].get("boss", false):
		var boss: Dictionary = aliens[0]
		boss["flash"] = maxf(0.0, boss["flash"] - delta)
		var margin := BOSS_SIZE / 2.0 + 16.0
		boss["p"].x += enemy_direction * 26.0 * delta
		if boss["p"].x < margin or boss["p"].x > W - margin:
			boss["p"].x = clampf(boss["p"].x, margin, W - margin)
			enemy_direction *= -1.0
		return
	for row in range(alien_rows.size()):
		var indices: Array[int] = []
		var left := W
		var right := 0.0
		for index in range(aliens.size()):
			if aliens[index]["row"] == row:
				indices.append(index)
				left = minf(left, aliens[index]["p"].x)
				right = maxf(right, aliens[index]["p"].x)
		if indices.is_empty():
			continue
		var movement: Dictionary = alien_rows[row]
		var dx: float = movement["direction"] * movement["speed"] * delta
		var descent := 0.0
		if left + dx < 30.0:
			dx = 30.0 - left
			movement["direction"] = 1.0
			descent = 22.0
		elif right + dx > W - 30.0:
			dx = W - 30.0 - right
			movement["direction"] = -1.0
			descent = 22.0
		for index in indices:
			aliens[index]["p"] += Vector2(dx, descent)

	for alien in aliens:
		if alien["p"].y >= PLAYER_Y - 34.0:
			lives = 0
			_finish_game()
			return


func _update_player_shots(delta: float) -> void:
	for i in range(player_shots.size() - 1, -1, -1):
		# Aceptar tambien posiciones simples para escenas/pruebas anteriores.
		var shot: Dictionary = player_shots[i] if player_shots[i] is Dictionary else {"p": player_shots[i], "hit_ids": {}}
		var previous: Vector2 = shot["p"]
		var bullet := previous + Vector2(0, -SHOT_SPEED * delta)
		var targets: Array[Dictionary] = []
		for alien in aliens:
			var hit_radius := minf(23.0, W * 0.035)
			if alien.get("boss", false):
				hit_radius = BOSS_SIZE * 0.42
			if not shot["hit_ids"].has(alien["id"]) and absf(bullet.x - alien["p"].x) < hit_radius and previous.y >= alien["p"].y - hit_radius and bullet.y <= alien["p"].y + hit_radius:
				targets.append(alien)
		# Primero el alien mas cercano a la nave, aun con frames largos.
		targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["p"].y > b["p"].y)
		var consumed := false
		for alien in targets:
			shot["hit_ids"][alien["id"]] = true
			if alien.get("boss", false) and alien["hp"] > 1:
				alien["hp"] -= 1
				alien["flash"] = 0.08
			else:
				_defeat_alien(aliens.find(alien))
			if piercing_left <= 0.0:
				consumed = true
				break
		if consumed or bullet.y < 75.0:
			player_shots.remove_at(i)
		else:
			shot["p"] = bullet
			player_shots[i] = shot


func _update_enemy_shots(delta: float) -> void:
	for i in range(enemy_shots.size() - 1, -1, -1):
		var previous_y: float = enemy_shots[i].y
		var bullet: Vector2 = enemy_shots[i] + Vector2(0, _enemy_bullet_speed() * delta)
		if bullet.y > H:
			enemy_shots.remove_at(i)
			continue

		if _damage_barrier(bullet):
			enemy_shots.remove_at(i)
			continue

		if shield_active and absf(bullet.x - player_x) < 44.0 * _shield_width_scale() and previous_y <= PLAYER_Y - 12.0 and bullet.y >= PLAYER_Y - 43.0:
			enemy_shots.remove_at(i)
			shield_active = false
			shield_flash = 0.25
			_explode(Vector2(bullet.x, PLAYER_Y - 34.0), VIOLET)
			continue

		if invulnerable <= 0.0 and absf(bullet.x - player_x) < _player_hit_half_width() and absf(bullet.y - PLAYER_Y) < 20.0:
			enemy_shots.remove_at(i)
			_explode(Vector2(player_x, PLAYER_Y), CYAN)
			lives -= 1
			invulnerable = 1.6
			if lives <= 0:
				_finish_game()
				return
			continue

		enemy_shots[i] = bullet


func _damage_barrier(bullet: Vector2) -> bool:
	for i in range(barriers.size() - 1, -1, -1):
		var block: Dictionary = barriers[i]
		if Rect2(block["p"], Vector2(14, 13)).has_point(bullet):
			block["hp"] -= 1
			if block["hp"] <= 0:
				barriers.remove_at(i)
			else:
				barriers[i] = block
			return true
	return false


func _explode(at: Vector2, color: Color) -> void:
	for i in range(13):
		var angle := randf_range(0.0, TAU)
		var speed := randf_range(45.0, 145.0)
		particles.append({
			"p": at,
			"v": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.2, 0.6),
			"color": color
		})


func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var spark: Dictionary = particles[i]
		spark["p"] += spark["v"] * delta
		spark["life"] -= delta
		if spark["life"] <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = spark


func _alien_color(kind: int) -> Color:
	if kind == 0:
		return Color("#ff55bd") # Fucsia
	if kind == 1:
		return Color("#5bf4d2") # Verde agua
	return Color("#539bff")     # Azul


func _draw_pixels(pattern: Array, center: Vector2, color: Color, pixel_size: float) -> void:
	var width: int = pattern[0].length()
	var origin := center - Vector2(width * pixel_size / 2.0, pattern.size() * pixel_size / 2.0)
	for row in range(pattern.size()):
		for col in range(width):
			if pattern[row].substr(col, 1) == "1":
				draw_rect(Rect2(origin + Vector2(col, row) * pixel_size, Vector2(pixel_size - 0.6, pixel_size - 0.6)), color)


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, SCREEN_H), DARK)
	# Cubrir el campo sin deformar la imagen, con recorte centrado.
	var background_size := UNIVERSE_BACKGROUND.get_size()
	var background_scale := maxf(W / background_size.x, H / background_size.y)
	var visible_region := Vector2(W, H) / background_scale
	draw_texture_rect_region(
		UNIVERSE_BACKGROUND,
		Rect2(0, 0, W, H),
		Rect2((background_size - visible_region) / 2.0, visible_region)
	)
	draw_rect(Rect2(0, 0, W, H), Color(0.005, 0.008, 0.02, BACKGROUND_DARKNESS))
	for star in stars:
		var alpha: float = 0.3 + 0.38 * (0.5 + 0.5 * sin(clock * 1.7 + star["phase"]))
		draw_circle(star["p"], star["r"], Color(0.7, 0.8, 1.0, alpha))
	if mode == "game_over":
		return

	draw_line(Vector2(25, 77), Vector2(W - 25, 77), Color(0.2, 0.36, 0.47), 2)
	draw_line(Vector2(25, H - 35), Vector2(W - 25, H - 35), Color(0.2, 0.36, 0.47), 2)

	var hud_width := W / 3.0 - 20.0
	var score_label := "PTS:%06d" % score if portrait else "PUNTOS: %06d" % score
	_draw_arcade_text(Vector2(16, 44), score_label, HORIZONTAL_ALIGNMENT_LEFT, hud_width, 16, CYAN)
	_draw_arcade_text(Vector2(W / 3.0 + 10, 44), "OLEADA %02d" % wave, HORIZONTAL_ALIGNMENT_CENTER, hud_width, 16, WHITE)
	_draw_arcade_text(Vector2(W * 2.0 / 3.0 + 4, 44), "VIDAS: %d" % lives, HORIZONTAL_ALIGNMENT_RIGHT, hud_width, 16, GOLD)
	var active_bonuses: Array[String] = []
	if shield_active:
		active_bonuses.append("ESCUDO LISTO")
	if rapid_fire_left > 0.0:
		active_bonuses.append("FUEGO X2: %02dS" % int(ceilf(rapid_fire_left)))
	if piercing_left > 0.0:
		active_bonuses.append("PERFORANTE: %02dS" % int(ceilf(piercing_left)))
	if triple_fire_left > 0.0:
		active_bonuses.append("TRIPLE: %02dS" % int(ceilf(triple_fire_left)))
	elif dual_cannons:
		active_bonuses.append("DOBLE CAÑÓN")
	_draw_arcade_text(Vector2(16, 66), " | ".join(active_bonuses), HORIZONTAL_ALIGNMENT_CENTER, W - 32, 8 if portrait else 16, _player_color())

	for block in barriers:
		var color: Color = GREEN if block["hp"] == 2 else Color(0.24, 0.54, 0.36)
		draw_rect(Rect2(block["p"], Vector2(14, 13)), color)

	for alien in aliens:
		if alien.get("boss", false):
			var bar := Rect2(40, 108, W - 80, 6)
			draw_rect(bar, Color(0.2, 0.08, 0.15))
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(alien["hp"]) / BOSS_HEALTH, bar.size.y)), PINK)
			if power_message_left <= 0.0:
				_draw_arcade_text(Vector2(16, 100), "JEFE NIVEL %d - %d/%d" % [wave, alien["hp"], BOSS_HEALTH], HORIZONTAL_ALIGNMENT_CENTER, W - 32, 8, GOLD)
		_draw_alien(alien)

	if mode != "game_over" or lives > 0:
		if invulnerable <= 0.0 or int(clock * 11.0) % 2 == 0:
			_draw_player()
		if shield_active or shield_flash > 0.0:
			_draw_player_shield()
	for item in power_ups:
		if item["kind"] == "bomb":
			_draw_bomb(item["p"], item["phase"])
		elif item["kind"] == "life":
			_draw_life(item["p"], item["phase"])
		else:
			_draw_power_up(item["p"], item["phase"])
	if power_message_left > 0.0:
		_draw_arcade_text(Vector2(16, 100), power_message, HORIZONTAL_ALIGNMENT_CENTER, W - 32, 8 if portrait else 16, GOLD)

	for shot in player_shots:
		var bullet: Vector2 = shot["p"] if shot is Dictionary else shot
		if piercing_left > 0.0:
			draw_rect(Rect2(bullet.x - 5, bullet.y - 15, 10, 27), Color(CYAN, 0.15))
		draw_rect(Rect2(bullet.x - 2.5, bullet.y - 11.0, 5.0, 18.0), WHITE if piercing_left > 0.0 else _player_color())
	for bullet in enemy_shots:
		draw_rect(Rect2(bullet.x - 2.5, bullet.y - 7.0, 5.0, 14.0), PINK)
	for spark in particles:
		draw_circle(spark["p"], 2.5, spark["color"])
	if bomb_flash > 0.0:
		draw_rect(Rect2(0, 77, W, H - 112), Color(1.0, 0.55, 0.15, bomb_flash * 0.35))

	if mode == "menu":
		_overlay("", "TOCA PARA EMPEZAR" if mobile else "ENTER PARA EMPEZAR", "Manten las flechas y FUEGO" if mobile else "A / D o flechas: mover | ESPACIO: disparar", true)
	elif mode == "paused":
		_overlay("PAUSA", "TOCA CONTINUAR" if mobile else "P / ENTER PARA CONTINUAR", "" if mobile else "O hace clic en el juego")

	var controls_help := "FLECHAS: MOVER | FUEGO: DISPARAR" if mobile else "A/D: MOVER | ESPACIO: DISPARAR | P: PAUSA"
	_draw_arcade_text(Vector2(16, H - 12), controls_help, HORIZONTAL_ALIGNMENT_CENTER, W - 32, 16, Color(0.55, 0.66, 0.74))
	if mobile:
		_draw_touch_controls()


func _draw_touch_controls() -> void:
	draw_rect(Rect2(0, H, W, SCREEN_H - H), Color(0.02, 0.03, 0.065))
	_draw_touch_button(TOUCH_LEFT, "<", CYAN, touch_actions.values().has("left"))
	_draw_touch_button(TOUCH_RIGHT, ">", CYAN, touch_actions.values().has("right"))
	_draw_touch_button(TOUCH_FIRE, "FUEGO", PINK, touch_actions.values().has("fire"))


func _alien_animation_frame(row: int = 0) -> int:
	return int((alien_animation_clock + row * 0.11) / ALIEN_FRAME_DURATION) % 3


func _draw_alien(alien: Dictionary) -> void:
	var at: Vector2 = alien["p"]
	var pixel_size := 12.0 if alien.get("boss", false) else 3.0
	var row: int = alien.get("row", 0)
	var color := _alien_color(alien["kind"])
	if alien.get("flash", 0.0) > 0.0:
		color = WHITE
	var pulse := 0.75 + 0.25 * sin(alien_animation_clock * 4.0 + row)
	for layer in range(3, 0, -1):
		draw_circle(at, pixel_size * (5.0 + layer), Color(color, 0.018 * pulse))
	var pattern: Array = ALIEN_HEAD + ALIEN_LEGS[_alien_animation_frame(row)]
	_draw_pixels(pattern, at, color, pixel_size)
	# Reflejos de los ojos dentro de la silueta, sin una textura externa.
	for eye_x in [-3.0, 3.0]:
		draw_rect(Rect2(at + Vector2(eye_x - 0.5, -1.5) * pixel_size, Vector2.ONE * pixel_size * 0.7), Color(WHITE, 0.85))


func _draw_power_up(at: Vector2, phase: float) -> void:
	var pulse := 0.75 + 0.25 * sin(clock * 7.0 + phase)
	for layer in range(4, 0, -1):
		draw_circle(at, 16.0 + layer * 5.0, Color(GOLD, 0.025 * pulse))
	_draw_pixels(POWER_BOLT, at + Vector2(-2, -2), GOLD, 3.0)
	for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		_draw_pixels(POWER_P, at + Vector2(4, 3) + offset, DARK, 3.0)
	_draw_pixels(POWER_P, at + Vector2(4, 3), Color(WHITE, 0.8 + pulse * 0.2), 3.0)


func _draw_life(at: Vector2, phase: float) -> void:
	var pulse := 0.7 + 0.3 * sin(clock * 7.0 + phase)
	for layer in range(3, 0, -1):
		draw_rect(Rect2(at - Vector2(28 + layer * 3, 16 + layer * 3), Vector2(56 + layer * 6, 32 + layer * 6)), Color(GREEN, 0.025 * pulse))
	draw_rect(Rect2(at - Vector2(29, 17), Vector2(58, 34)), DARK)
	draw_rect(Rect2(at - Vector2(29, 17), Vector2(58, 34)), GREEN, false, 2.0)
	_draw_arcade_text(at + Vector2(-28, 7), "1UP", HORIZONTAL_ALIGNMENT_CENTER, 56, 16, Color(GREEN, pulse))


func _draw_bomb(at: Vector2, phase: float) -> void:
	var pulse := 0.7 + 0.3 * sin(clock * 9.0 + phase)
	for layer in range(4, 0, -1):
		draw_circle(at, 18.0 + layer * 4.0, Color(PINK, 0.03 * pulse))
	_draw_pixels(BOMB_SPRITE, at, Color(0.40, 0.44, 0.58), 3.0)
	draw_rect(Rect2(at + Vector2(-7, -2), Vector2(6, 3)), WHITE)
	draw_rect(Rect2(at + Vector2(-10, 1), Vector2(3, 6)), WHITE)
	var spark := at + Vector2(10, -22)
	draw_rect(Rect2(spark - Vector2(1.5, 5), Vector2(3, 10)), Color(GOLD, pulse))
	draw_rect(Rect2(spark - Vector2(5, 1.5), Vector2(10, 3)), Color(GOLD, pulse))


func _draw_player() -> void:
	var center := Vector2(player_x, PLAYER_Y)
	match _player_cannon_count():
		1:
			_draw_pixels(PLAYER_SPRITE, center, CYAN, 5.0)
		2:
			_draw_pixels(PLAYER_DOUBLE_SPRITE, center, SHIP_BLUE, 5.0)
			_draw_pixels(["0110", "1111", "0110"], center + Vector2(0, 2), CYAN, 2.0)
			for offset in [-20.0, 20.0]:
				draw_rect(Rect2(center + Vector2(offset - 1.5, -21), Vector2(3, 7)), WHITE)
				draw_rect(Rect2(center + Vector2(offset - 3, 18), Vector2(6, 5)), GOLD)
		3:
			_draw_pixels(PLAYER_TRIPLE_SPRITE, center, VIOLET, 5.0)
			_draw_pixels(["00100", "01110", "11111", "01110", "00100"], center, WHITE, 2.0)
			for offset in [-30.0, 0.0, 30.0]:
				draw_rect(Rect2(center + Vector2(offset - 1.5, -24), Vector2(3, 8)), CYAN)
			for offset in [-23.0, 23.0]:
				draw_rect(Rect2(center + Vector2(offset - 4, 6), Vector2(8, 3)), PINK)
				draw_rect(Rect2(center + Vector2(offset - 3, 22), Vector2(6, 6)), GOLD)


func _draw_player_shield() -> void:
	# Arco escalonado hacia los enemigos, con varias capas de aura violeta.
	var arc := PackedVector2Array([
		Vector2(-42, -7), Vector2(-42, -22), Vector2(-30, -22),
		Vector2(-30, -34), Vector2(-14, -34), Vector2(-14, -40),
		Vector2(14, -40), Vector2(14, -34), Vector2(30, -34),
		Vector2(30, -22), Vector2(42, -22), Vector2(42, -7)
	])
	for index in range(arc.size()):
		arc[index].x *= _shield_width_scale()
		arc[index] += Vector2(player_x, PLAYER_Y)
	var pulse := 0.8 + 0.2 * sin(clock * 6.0)
	draw_polyline(arc, Color(VIOLET, 0.05 * pulse), 20.0)
	draw_polyline(arc, Color(VIOLET, 0.12 * pulse), 12.0)
	draw_polyline(arc, Color(VIOLET, 0.35 * pulse), 6.0)
	draw_polyline(arc, Color(VIOLET, pulse), 2.0)


func _draw_touch_button(rect: Rect2, label: String, color: Color, pressed: bool) -> void:
	draw_style_box(_touch_button_style(color, pressed), rect)
	_draw_arcade_text(rect.position + Vector2(12, rect.size.y / 2.0 + 8), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 24, 24, color)


func _draw_arcade_text(at: Vector2, text: String, alignment: HorizontalAlignment, available_width: float, preferred_size: int, color: Color) -> void:
	var label := text.to_upper()
	var font_size := preferred_size
	# Pasos de 8 para mantener regulares los pixeles de la fuente.
	while font_size > 8 and ARCADE_FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_width:
		font_size -= 8
	draw_string(ARCADE_FONT, at.round(), label, alignment, available_width, font_size, color)


func _touch_button_style(color: Color, pressed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.3 if pressed else 0.08)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	return style


func _overlay(title: String, subtitle: String, help: String, show_logo: bool = false) -> void:
	var panel_height := 420.0 if show_logo else 302.0
	var panel := Rect2(24, H / 2.0 - panel_height / 2.0, W - 48, panel_height)
	draw_rect(panel, Color(0.02, 0.04, 0.10, 0.95))
	draw_rect(panel, CYAN, false, 2.0)
	var text_width := panel.size.x - 32
	var text_x := panel.position.x + 16
	if show_logo:
		var logo_scale := minf(text_width / START_LOGO.get_width(), 270.0 / START_LOGO.get_height())
		var logo_size := START_LOGO.get_size() * logo_scale
		draw_texture_rect(START_LOGO, Rect2(Vector2(W / 2.0 - logo_size.x / 2.0, panel.position.y + 20 + (270.0 - logo_size.y) / 2.0), logo_size), false)
	else:
		_draw_arcade_text(Vector2(text_x, panel.position.y + 95), title, HORIZONTAL_ALIGNMENT_CENTER, text_width, 32 if portrait else 40, CYAN)
	_draw_arcade_text(Vector2(text_x, panel.position.y + (325 if show_logo else 179)), subtitle, HORIZONTAL_ALIGNMENT_CENTER, text_width, 24, GOLD)
	_draw_arcade_text(Vector2(text_x, panel.position.y + (388 if show_logo else 242)), help, HORIZONTAL_ALIGNMENT_CENTER, text_width, 16, WHITE)
