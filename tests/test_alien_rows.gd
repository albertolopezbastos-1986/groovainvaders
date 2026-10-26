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
	check(game.alien_rows.size() == 4, "Estado independiente para las cuatro filas")
	for row in range(4):
		check(game.alien_rows[row]["speed"] >= 28.0 and game.alien_rows[row]["speed"] <= 46.0, "Velocidad inicial razonable")
		if row > 0:
			check(game.alien_rows[row]["direction"] == -game.alien_rows[row - 1]["direction"], "Filas vecinas comienzan en direcciones opuestas")
		for other in range(row):
			check(not is_equal_approx(game.alien_rows[row]["speed"], game.alien_rows[other]["speed"]), "Velocidades diferentes por fila")
	var before: Array = game.aliens.duplicate(true)
	game._move_aliens(0.1)
	for index in range(game.aliens.size()):
		var row: int = game.aliens[index]["row"]
		var shift: Vector2 = game.aliens[index]["p"] - before[index]["p"]
		check(is_equal_approx(shift.x, game.alien_rows[row]["direction"] * game.alien_rows[row]["speed"] * 0.1) and shift.y == 0.0, "Cada alien conserva la velocidad comun de su fila")
	game._spawn_wave()
	for alien in game.aliens:
		if alien["row"] == 0:
			alien["p"].x -= 50.0
	game.alien_rows[0]["direction"] = -1.0
	game.alien_rows[0]["speed"] = 40.0
	game.alien_rows[1]["direction"] = 1.0
	game.alien_rows[1]["speed"] = 30.0
	before = game.aliens.duplicate(true)
	game._move_aliens(0.1)
	check(game.alien_rows[0]["direction"] == 1.0 and game.alien_rows[1]["direction"] == 1.0, "Rebotar solo invierte la fila que toca pared")
	for index in range(game.aliens.size()):
		var shift: Vector2 = game.aliens[index]["p"] - before[index]["p"]
		if game.aliens[index]["row"] == 0:
			check(is_equal_approx(shift.x, -1.0) and shift.y == 22.0, "Fila completa rebota junta sin deformarse")
		elif game.aliens[index]["row"] == 1:
			check(is_equal_approx(shift.x, 3.0) and shift.y == 0.0, "Otra fila continua su recorrido")
	for index in range(game.aliens.size() - 1, -1, -1):
		if game.aliens[index]["row"] == 0:
			game.aliens.remove_at(index)
	game._move_aliens(0.1)
	check(game.aliens.size() == 30, "Eliminar una fila no afecta el movimiento de las otras")
	game.wave = 21
	game._spawn_wave()
	for movement in game.alien_rows:
		check(movement["speed"] >= 68.0 and movement["speed"] <= 86.0, "Rangos aumentan con el nivel")
	game.wave = 101
	game._spawn_wave()
	for movement in game.alien_rows:
		check(movement["speed"] <= 118.0, "Limite de velocidad en niveles avanzados")
	for frame in range(3):
		game.alien_animation_clock = frame * 0.18 + 0.001
		check(game._alien_animation_frame() == frame, "Animacion muestra cada uno de los tres frames")
		var pattern: Array = game.ALIEN_HEAD + game.ALIEN_LEGS[frame]
		for line in pattern:
			check(line.length() == 13, "Todos los pixeles mantienen ancho estable")
	game.alien_animation_clock = 0.541
	check(game._alien_animation_frame() == 0, "Animacion repite sin variar tamano")
	game.mode = "paused"
	var frozen: float = game.alien_animation_clock
	game._process(1.0)
	check(game.alien_animation_clock == frozen, "Pausa congela patitas y glow")
	game.mode = "playing"
	game.wave = 10
	game._spawn_wave()
	game._enemy_volley()
	check(is_equal_approx(game.enemy_shot_delay, 1.32), "Jefe dispara a mitad de la frecuencia anterior")
	var shot_y: float = game.enemy_shots[0].y
	game._update_enemy_shots(0.1)
	check(is_equal_approx(game.enemy_shots[0].y - shot_y, 40.0), "Velocidad del rayo del jefe no cambia")
	game.music_player.stop()
	game.queue_free()
	await process_frame
	print("ALIEN ROW AND ANIMATION TESTS: ", "OK" if failures == 0 else "%d FALLOS" % failures)
	quit(0 if failures == 0 else 1)
