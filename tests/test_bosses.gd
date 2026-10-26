extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _run() -> void:
	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start_game()
	game.mobile = false
	root.size = Vector2i(1920, 1080)
	game.last_window_size = Vector2i.ZERO
	game._update_layout()
	check(game.W == 540.0 and game.H == 800.0 and game.SCREEN_H == 960.0, "Desktop conserva campo vertical fijo")
	check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "Franjas en lugar de estirar")
	game.mobile = true
	root.size = Vector2i(390, 844)
	game.last_window_size = Vector2i.ZERO
	game._update_layout()
	check(game.W == 540.0 and game.H == 800.0 and game.SCREEN_H == 960.0, "Mobile usa el mismo campo y jugabilidad")
	check(game.TOUCH_LEFT.size == Vector2(142, 136) and game.TOUCH_FIRE.size == Vector2(202, 136), "Botones tactiles agrandados")
	check(game.TOUCH_LEFT.end.x < game.TOUCH_RIGHT.position.x and game.TOUCH_RIGHT.end.x < game.TOUCH_FIRE.position.x, "Botones sin superposicion")
	check(game.TOUCH_FIRE.end.x <= game.W and game.TOUCH_FIRE.end.y <= game.SCREEN_H, "Botones dentro de pantalla")
	game.mode = "paused"
	game._press_touch(0, game.TOUCH_START.get_center())
	check(game.mode == "playing", "Pausa por perdida de foco se reanuda tocando el cartel")
	for level in [10, 20, 30, 40]:
		game.wave = level
		game._spawn_wave()
		check(game.aliens.size() == 1 and game.aliens[0].get("boss", false) and game.aliens[0]["hp"] == 50, "Jefe unico con 50 HP en nivel %d" % level)
	game.wave = 9
	game._spawn_wave()
	check(game.aliens.size() == 40, "Nivel 9 normal")
	game.wave = 10
	game._spawn_wave()
	game.score = 0
	var start_x: float = game.aliens[0]["p"].x
	game._move_aliens(0.5)
	check(is_equal_approx(absf(game.aliens[0]["p"].x - start_x), 13.0), "Jefe lento: 26 unidades por segundo")
	game._enemy_volley()
	check(game.enemy_shots.size() == 3 and is_equal_approx(game.enemy_shot_delay, 1.32), "Rafagas a mitad de la frecuencia anterior")
	game.enemy_shots.clear()
	for shot in range(49):
		game.player_shots.append(game.aliens[0]["p"])
	game._update_player_shots(0.0)
	check(game.aliens.size() == 1 and game.aliens[0]["hp"] == 1 and game.score == 0, "Jefe sobrevive 49 impactos sin dar puntos prematuros")
	game.player_shots.append(game.aliens[0]["p"])
	game._update_player_shots(0.0)
	check(game.aliens.is_empty() and game.score == 2000, "Impacto 50 mata al jefe y da puntos una sola vez")
	game._update_game(0.0)
	check(game.wave == 11 and game.aliens.size() == 40, "Nivel 11 vuelve a formacion normal")
	game.wave = 20
	game._spawn_wave()
	game._apply_power_up("bomb")
	check(game.aliens.is_empty(), "La bomba conserva su efecto sobre el jefe")
	game._start_game()
	check(game.wave == 1 and game.aliens.size() == 40, "Reinicio vuelve al nivel 1 normal")
	game.music_player.stop()
	game.queue_free()
	await process_frame
	print("BOSS AND LAYOUT TESTS: ", "OK" if failures == 0 else "%d FALLOS" % failures)
	quit(0 if failures == 0 else 1)
