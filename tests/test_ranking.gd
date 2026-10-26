extends SceneTree

const Service = preload("res://OnlineScores.gd")
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var test_url := OS.get_environment("INVASORES_TEST_API_URL")
	if test_url.is_empty():
		push_error("Esta prueba requiere tests/http-fixture.mjs y INVASORES_TEST_API_URL")
		quit(1)
		return
	ProjectSettings.set_setting("ranking/api_base_url", test_url)
	var first := Service.new()
	root.add_child(first)
	check(first.clean_name("  ") == "JUGADOR", "Nombre vacio")
	check(first.clean_name("abcdefghijklmnop") == "ABCDEFGHIJKL", "Limite de nombre")
	check(first.clean_name("a\nb\tc<script>") == "ABCSCRIPT", "Limpiar nombre")
	var first_id := first.new_run_id()
	check(first_id.length() == 32, "Id aleatorio por partida")
	first.submit("BETO", 8500, first_id)
	var response: Array = await first.score_saved
	check(response[0] and response[1]["name"] == "BETO", "Guardar por HTTP")
	first.submit("BETO", 8500, first_id)
	response = await first.score_saved
	check(response[0], "Reintento idempotente")
	var second := Service.new()
	root.add_child(second)
	second.submit("CAMILA", 9200, second.new_run_id())
	response = await second.score_saved
	check(response[0], "Segundo dispositivo")
	first.load_scores()
	response = await first.scores_loaded
	check(response[0] and first.scores.size() == 2, "Dos dispositivos comparten tabla sin duplicado")
	check(first.scores[0]["name"] == "CAMILA" and first.scores[1]["name"] == "BETO", "Orden mundial")
	check(not first.scores[0]["date"].is_empty(), "Fecha del servidor")
	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start_game()
	var previous_id: String = game.current_run_id
	game.score = 1230
	game.lives = 1
	game.enemy_shots = [Vector2(game.player_x, game.PLAYER_Y)]
	game._update_enemy_shots(0.0)
	check(game.mode == "game_over" and game.game_over_panel.visible, "Game over por ultima vida")
	check(not game.restart_button.disabled, "Conexion nunca bloquea otra partida")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_P
	game._input(key)
	check(game.mode == "game_over", "Escribir P no pausa ni reinicia")
	game.name_input.text_submitted.emit("MARINA")
	check(game.score_saving and game.save_score_button.disabled, "Evitar doble clic mientras guarda")
	await game.online_scores.score_saved
	check(game.score_submitted, "ENTER guarda online")
	await game.online_scores.scores_loaded
	game._submit_score("DUPLICADO")
	check(game.online_scores.scores.size() == 3, "Solo una entrada por partida")
	var highlighted := 0
	for row in game.ranking_rows:
		if row.text.begins_with(">"):
			highlighted += 1
	check(highlighted == 1, "Destacar resultado actual por id, no por nombre")
	game._start_game()
	check(game.mode == "playing" and not game.game_over_panel.visible, "Reinicio oculta ranking")
	check(previous_id != game.current_run_id, "Cada partida tiene id nuevo")
	game.aliens[0]["p"].y = game.PLAYER_Y
	game._move_aliens(0.0)
	check(game.mode == "game_over", "Game over por invasion")
	game.online_scores.base_url = test_url + "/offline"
	game._submit_score("X")
	await game.online_scores.score_saved
	check(not game.score_submitted and not game.restart_button.disabled and not game.save_score_button.disabled, "Fallo de red permite reintentar o jugar")
	check(not game.name_input.editable, "Reintento conserva identidad del envio")
	game.mobile = true
	root.size = Vector2i(390, 844)
	game.last_window_size = Vector2i.ZERO
	game._update_layout()
	await process_frame
	check(game.game_over_panel.size.x <= game.W, "Ranking cabe en celular")
	for row in game.ranking_rows:
		check(row.get_minimum_size().x <= game.game_over_panel.size.x - 36, "Fila cabe en celular")
	game.online_scores.cancel_pending()
	game.music_player.stop()
	first.queue_free()
	second.queue_free()
	game.queue_free()
	await process_frame
	print("ONLINE RANKING TESTS: ", "OK" if failures == 0 else "%d FALLOS" % failures)
	quit(0 if failures == 0 else 1)
