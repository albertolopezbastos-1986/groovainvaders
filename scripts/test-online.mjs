import { spawn } from 'node:child_process';
import { once } from 'node:events';

const fixture = spawn(process.execPath, ['tests/http-fixture.mjs'], { stdio: ['ignore', 'pipe', 'inherit'] });
let timer;
try {
  const startup = new Promise((resolve, reject) => {
    fixture.stdout.once('data', (data) => resolve(data.toString().trim()));
    fixture.once('error', reject);
    fixture.once('exit', (code) => reject(new Error(`Fixture no pudo iniciar (${code})`)));
    timer = setTimeout(() => reject(new Error('Timeout iniciando fixture HTTP')), 5000);
  });
  const url = await startup;
  clearTimeout(timer);
  const game = spawn(process.env.GODOT_BIN || 'godot', [
    '--headless', '--path', process.env.GODOT_PROJECT || '.', '--script', 'res://tests/test_ranking.gd'
  ], { stdio: 'inherit', env: { ...process.env, INVASORES_TEST_API_URL: url } });
  timer = setTimeout(() => game.kill(), 45000);
  const [code] = await once(game, 'exit');
  process.exitCode = code ?? 1;
} finally {
  clearTimeout(timer);
  fixture.kill();
}
