extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func lined_targets(game: Node2D) -> void:
	game.aliens = game.aliens.slice(0, 3)
	for index in range(3):
		game.aliens[index]["p"] = Vector2(270, 200 + index * 100)


func _run() -> void:
	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start_game()
	check(game.life_drop_delay >= 90.0 and game.life_drop_delay <= 150.0, "1UP tiene la misma frecuencia inicial rara")
	game.bomb_drop_delay = 0.0
	game.life_drop_delay = 0.0
	game._defeat_alien(0, false)
	check(game.power_ups.size() == 2, "Bomba y 1UP pueden caer de la misma baja sin excluirse")
	check(game.power_ups[0]["kind"] == "bomb" and game.power_ups[1]["kind"] == "life", "Iconos y clases independientes")
	check(game.life_drop_delay >= 120.0 and game.life_drop_delay <= 180.0, "1UP usa el mismo rango posterior raro")
	check(game.power_ups[0]["p"] != game.power_ups[1]["p"], "Iconos simultaneos separados para distinguirlos")
	var life_delay: float = game.life_drop_delay
	game.bomb_drop_delay = 0.0
	game._try_drop_bomb(Vector2(100, 200))
	check(game.life_drop_delay == life_delay, "Caer bomba no reinicia reloj del 1UP")
	game._start_game()
	game.power_ups.append({"p": Vector2(game.player_x, game.PLAYER_Y), "kind": "life", "phase": 0.0})
	game._update_power_ups(0.0)
	check(game.lives == 4 and game.power_ups.is_empty(), "Recoger 1UP suma una vida")
	game._apply_power_up("life")
	check(game.lives == 5, "Vidas extra acumulables")
	game._start_game()
	lined_targets(game)
	game.player_shots.append(Vector2(270, 450))
	game._update_player_shots(0.5)
	check(game.aliens.size() == 2 and game.player_shots.is_empty() and game.score == 30, "Rayo normal mata solo al mas cercano, incluso con frame largo")
	game._start_game()
	lined_targets(game)
	game._apply_power_up("piercing")
	game.player_shots.append(Vector2(270, 450))
	game._update_player_shots(0.5)
	check(game.aliens.is_empty() and game.score == 90 and game.player_shots.size() == 1, "Un rayo perfora tres aliens y suma los tres puntajes")
	game._start_game()
	game.wave = 10
	game._spawn_wave()
	game._apply_power_up("piercing")
	game.player_shots.append(game.aliens[0]["p"] + Vector2(0, 40))
	for tick in range(5):
		game._update_player_shots(0.02)
	check(game.aliens[0]["hp"] == 49, "Un rayo perforante solo dana una vez al jefe durante su paso")
	game._apply_power_up("shield")
	game._apply_power_up("rapid")
	game._apply_power_up("weapon")
	game._apply_power_up("weapon")
	game.piercing_left = 1.0
	game.mode = "paused"
	game._process(2.0)
	check(game.piercing_left == 1.0, "Pausa congela perforacion")
	game.mode = "playing"
	game._update_player_bonuses(1.0)
	check(game.piercing_left == 0.0 and game.shield_active and game.rapid_fire_left == 9.0 and game.triple_fire_left == 9.0, "Perforacion expira sin eliminar otros bonus")
	game.player_shots.clear()
	game.player_shots.append(game.aliens[0]["p"])
	game._update_player_shots(0.0)
	check(game.aliens[0]["hp"] == 48 and game.player_shots.is_empty(), "Al expirar vuelve a desaparecer en el primer impacto")
	game._apply_power_up("piercing")
	game.piercing_left = 2.0
	game._apply_power_up("piercing")
	check(game.piercing_left == 10.0, "Recoger otra perforacion renueva diez segundos")
	game._spawn_wave()
	check(game.piercing_left == 10.0, "Cambio de oleada conserva perforacion")
	game._start_game()
	check(game.piercing_left == 0.0 and game.lives == 3, "Reinicio limpia perforacion y vidas de partida anterior")
	game.music_player.stop()
	game.queue_free()
	await process_frame
	print("1UP AND PIERCING TESTS: ", "OK" if failures == 0 else "%d FALLOS" % failures)
	quit(0 if failures == 0 else 1)
