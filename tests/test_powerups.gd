extends SceneTree

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var scene: PackedScene = load("res://Main.tscn") as PackedScene
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start_game()
	check(game.power_drop_delay >= 20.0 and game.power_drop_delay <= 30.0, "Primer bonus espaciado de 20 a 30 segundos")
	var kinds := {"shield": 0, "rapid": 0, "weapon": 0, "piercing": 0, "repair": 0}
	for roll in range(400):
		kinds[game._power_up_kind((roll + 0.5) / 400.0)] += 1
	check(kinds == {"shield": 90, "rapid": 90, "weapon": 90, "piercing": 90, "repair": 40}, "Probabilidades 22.5/22.5/22.5/22.5/10")
	game.power_drop_delay = 3.0
	game.player_shots = [game.aliens[0]["p"]]
	game._update_player_shots(0.0)
	check(game.power_ups.is_empty(), "Una baja antes del intervalo no suelta bonus")
	game._update_power_ups(3.0)
	check(game.power_ups.is_empty() and game.power_drop_delay == 0.0, "Vencer el tiempo solo deja el bonus pendiente")
	game._update_power_ups(30.0)
	check(game.power_ups.is_empty() and game.power_drop_delay == 0.0, "El bonus pendiente no se pierde al esperar una baja")
	var defeated_at: Vector2 = game.aliens[0]["p"]
	game.player_shots = [defeated_at]
	game._update_player_shots(0.0)
	check(game.power_ups.size() == 1 and game.power_ups[0]["p"] == defeated_at, "El disparo mortal genera el bonus desde el alien derrotado")
	check(game.power_drop_delay >= 30.0 and game.power_drop_delay <= 45.0, "Intervalo aleatorio de 30 a 45 segundos")
	game.player_shots = [game.aliens[0]["p"], game.aliens[1]["p"]]
	game._update_player_shots(0.0)
	check(game.power_ups.size() == 1, "Bajas seguidas no duplican el bonus")
	game.power_ups.clear()
	game.power_ups.append({"p": Vector2(70, 100), "kind": "shield", "phase": 0.0})
	game.wave = 4
	game._update_power_ups(0.5)
	check(is_equal_approx(game.power_ups[0]["p"].y - 100.0, game._enemy_bullet_speed() * 0.25), "Mitad de velocidad de las balas en cualquier oleada")
	game.power_ups.clear()
	game.power_ups.append({"p": Vector2(game.player_x, game.PLAYER_Y - 60), "kind": "shield", "phase": 0.0})
	game._update_power_ups(0.5)
	check(game.shield_active and game.power_ups.is_empty(), "Recogida por barrido sin saltarse la nave")
	game.enemy_shots = [Vector2(game.player_x, game.PLAYER_Y - 80)]
	var lives_before: int = game.lives
	game._update_enemy_shots(0.2)
	check(not game.shield_active and game.lives == lives_before and game.enemy_shots.is_empty(), "Escudo absorbe un impacto frontal")
	game.enemy_shots = [Vector2(game.player_x, game.PLAYER_Y)]
	game._update_enemy_shots(0.0)
	check(game.lives == lives_before - 1, "Segundo disparo sin escudo hace dano")
	game._start_game()
	game._apply_power_up("rapid")
	check(game.rapid_fire_left == 10.0, "Disparo rapido dura diez segundos")
	game.touch_actions[0] = "fire"
	game.shot_delay = 0.0
	game._update_game(0.0)
	check(is_equal_approx(game.shot_delay, 0.115), "Cadencia doble")
	game.mode = "paused"
	game._process(2.0)
	check(game.rapid_fire_left == 10.0, "La pausa congela los temporizadores")
	game.mode = "playing"
	game.shot_delay = 0.0
	game._update_game(10.0)
	check(game.rapid_fire_left == 0.0 and is_equal_approx(game.shot_delay, 0.23), "Cadencia normal al expirar")
	game._apply_power_up("rapid")
	game.rapid_fire_left = 2.0
	game._apply_power_up("rapid")
	check(game.rapid_fire_left == 10.0, "Recoger otro renueva el tiempo")
	# Verificar todas las formas y acumulacion sin avanzar enemigos ni red.
	game._start_game()
	game._fire_player_shots()
	check(game.player_shots.size() == 1 and game.player_shots[0]["p"].x == game.player_x, "Forma inicial dispara desde el centro")
	game.player_shots.clear()
	game._apply_power_up("shield")
	game._apply_power_up("rapid")
	game._apply_power_up("weapon")
	check(game._player_cannon_count() == 2 and game._player_color() == game.SHIP_BLUE, "Primer armamento activa nave doble azul")
	check(game.shield_active and game.rapid_fire_left == 10.0, "Escudo + doble pico + rapidez coexisten")
	game._fire_player_shots()
	check(game.player_shots.size() == 2 and game.player_shots[0]["p"].x == game.player_x - 20.0 and game.player_shots[1]["p"].x == game.player_x + 20.0, "Doble dispara desde ambos picos sin disparo central")
	game._apply_power_up("shield")
	check(game._player_cannon_count() == 2 and game.rapid_fire_left == 10.0, "Escudo repetido no reemplaza los otros bonus")
	game.player_shots.clear()
	game._apply_power_up("weapon")
	check(game._player_cannon_count() == 3 and game._player_color() == game.VIOLET and game.triple_fire_left == 10.0, "Segundo armamento activa triple violeta por diez segundos")
	game._fire_player_shots()
	check(game.player_shots.size() == 3 and game.player_shots[0]["p"].x == game.player_x - 30.0 and game.player_shots[1]["p"].x == game.player_x and game.player_shots[2]["p"].x == game.player_x + 30.0, "Triple dispara desde los tres picos")
	game.touch_actions[0] = "fire"
	game.shot_delay = 0.0
	game.player_shots.clear()
	game._update_game(0.0)
	check(game.player_shots.size() == 3 and is_equal_approx(game.shot_delay, 0.115), "Triple rapido emite tres rayos con doble cadencia")
	game.rapid_fire_left = 3.0
	game._update_player_bonuses(3.0)
	check(game.rapid_fire_left == 0.0 and game._player_cannon_count() == 3 and game.shield_active, "Expirar rapidez conserva triple y escudo")
	game._update_player_bonuses(7.0)
	check(game._player_cannon_count() == 2 and game._player_color() == game.SHIP_BLUE and game.shield_active, "Expirar triple devuelve doble azul y conserva escudo")
	game._apply_power_up("weapon")
	game.triple_fire_left = 1.0
	game._apply_power_up("rapid")
	game._update_player_bonuses(1.0)
	check(game._player_cannon_count() == 2 and game.rapid_fire_left == 9.0, "Expirar triple no elimina rapidez")
	game._apply_power_up("weapon")
	game.triple_fire_left = 2.0
	game._apply_power_up("weapon")
	check(game.triple_fire_left == 10.0, "Otro armamento durante triple renueva diez segundos")
	game.mode = "paused"
	game._process(2.0)
	check(game.triple_fire_left == 10.0 and game.rapid_fire_left == 9.0, "Pausa congela los dos temporizadores")
	game.mode = "playing"
	game._spawn_wave()
	check(game._player_cannon_count() == 3 and game.rapid_fire_left == 9.0 and game.shield_active, "Cambio de oleada conserva todas las combinaciones")
	game.player_x = 1.0
	game._apply_power_up("weapon")
	check(game.player_x >= game._player_margin(), "La nave grande no sale de la pantalla al mejorar")
	check(game.PLAYER_DOUBLE_SPRITE[0].length() > game.PLAYER_SPRITE[0].length() and game.PLAYER_TRIPLE_SPRITE[0].length() > game.PLAYER_DOUBLE_SPRITE[0].length(), "Cada forma crece de tamano")
	for pattern in [game.PLAYER_SPRITE, game.PLAYER_DOUBLE_SPRITE, game.PLAYER_TRIPLE_SPRITE]:
		for row in pattern:
			check(row.length() == pattern[0].length(), "Filas del sprite tienen el mismo ancho")
	game._start_game()
	var complete_barriers: int = game.barriers.size()
	game.barriers[0]["hp"] = 1
	game.barriers.remove_at(1)
	game._apply_power_up("repair")
	check(game.barriers.size() == complete_barriers, "Reparar repone bloques destruidos")
	for block in game.barriers:
		check(block["hp"] == 2, "Reparar restaura todos los puntos de vida")
	game._apply_power_up("repair")
	check(game.barriers.size() == complete_barriers, "Reparaciones sucesivas no duplican bloques")
	game._apply_power_up("shield")
	game._apply_power_up("rapid")
	game._spawn_wave()
	check(game.shield_active and game.rapid_fire_left == 10.0, "Bonuses conservados entre oleadas")
	game.power_ups.clear()
	game.power_ups.append({"p": Vector2(100, 200), "kind": "repair", "phase": 0.0})
	var old_size := Vector2(game.W, game.H)
	game.W = 540.0
	game.H = 960.0
	game._remap_game(old_size)
	check(is_equal_approx(game.power_ups[0]["p"].x, 100.0 * 540.0 / old_size.x), "Power-up se adapta al girar pantalla")
	game._start_game()
	check(not game.shield_active and game.rapid_fire_left == 0.0 and not game.dual_cannons and game.triple_fire_left == 0.0 and game.power_ups.is_empty(), "Nueva partida limpia todos los bonuses")
	game.power_ups.clear()
	game.power_ups.append({"p": Vector2(40, game.H + 40), "kind": "shield", "phase": 0.0})
	game._update_power_ups(0.0)
	check(game.power_ups.is_empty(), "Eliminar bonus fuera de pantalla")
	game._start_game()
	check(game.bomb_drop_delay >= 90.0 and game.bomb_drop_delay <= 150.0, "Bomba mucho mas espaciada que las P")
	game._try_drop_bomb(Vector2(100, 200))
	check(game.power_ups.is_empty(), "No aparece bomba antes del intervalo")
	game.bomb_drop_delay = 0.0
	game._try_drop_bomb(Vector2(100, 200))
	game._try_drop_bomb(Vector2(120, 200))
	check(game.power_ups.size() == 1 and game.power_ups[0]["kind"] == "bomb", "Solo una bomba por intervalo")
	check(game.bomb_drop_delay >= 120.0 and game.bomb_drop_delay <= 180.0, "Bombas sucesivas cada 120-180 segundos")
	game._update_power_ups(0.5)
	check(is_equal_approx(game.power_ups[0]["p"].y - 200.0, game._enemy_bullet_speed() * 0.3), "Bomba cae un veinte por ciento mas rapido que P")
	game._start_game()
	game.power_drop_delay = 0.0
	game.bomb_drop_delay = 0.0
	game._apply_power_up("shield")
	game._apply_power_up("rapid")
	game._apply_power_up("weapon")
	game._apply_power_up("weapon")
	game.enemy_shots = [Vector2(game.player_x, game.PLAYER_Y - 40)]
	game.power_ups.append({"p": Vector2(game.player_x, game.PLAYER_Y), "kind": "bomb", "phase": 0.0})
	game._update_power_ups(0.0)
	check(game.aliens.is_empty() and game.score == 700, "Bomba recogida elimina toda la oleada y suma los 700 puntos exactos")
	check(game.enemy_shots.is_empty() and game.lives == 3, "La bomba elimina los rayos sin danar al jugador")
	check(game.power_ups.size() == 1 and game.power_ups[0]["kind"] != "bomb", "La explosion suelta la P pendiente sin crear bombas recursivas")
	check(game.shield_active and game.rapid_fire_left == 10.0 and game.triple_fire_left == 10.0, "Bomba conserva todos los bonus acumulados")
	game._update_game(0.3)
	check(game.wave == 1 and game.aliens.is_empty(), "Breve pausa visual antes de la nueva oleada")
	game._update_game(0.31)
	check(game.wave == 2 and game.aliens.size() == 40, "La siguiente oleada aparece una sola vez")
	game._start_game()
	game.power_drop_delay = 20.0
	game._defeat_alien(0, false)
	game._apply_power_up("bomb")
	check(game.score == 700 and game.power_ups.is_empty(), "No duplica puntos de aliens ya muertos ni adelanta una P")
	game._start_game()
	check(game.bomb_flash == 0.0 and game.bomb_wave_delay == 0.0, "Reiniciar limpia efectos de bomba")
	game.music_player.stop()
	game.queue_free()
	await process_frame
	print("POWERUP TESTS: ", "OK" if failures == 0 else "%d FALLOS" % failures)
	quit(0 if failures == 0 else 1)
