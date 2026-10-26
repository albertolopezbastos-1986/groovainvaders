import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, utimesSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const buildScript = resolve('scripts/check-web.mjs');

test('build habilita el teclado en un HTML exportado con experimentalVK false y es repetible', () => {
  const folder = mkdtempSync(join(tmpdir(), 'invasores-web-keyboard-'));
  try {
    const web = join(folder, 'web');
    mkdirSync(web);
    for (const name of ['index.js', 'index.wasm', 'index.pck']) writeFileSync(join(web, name), 'fixture');
    writeFileSync(join(web, 'index.html'), '<html><head><script src="index.js"></script></head><body><script>const GODOT_CONFIG={"experimentalVK":false,"focusCanvas":true};</script></body></html>');
    for (let attempt = 0; attempt < 2; attempt++) {
      const result = spawnSync(process.execPath, [buildScript], { cwd: folder, encoding: 'utf8' });
      assert.equal(result.status, 0, result.stderr);
      const html = readFileSync(join(web, 'index.html'), 'utf8');
      assert.match(html, /"experimentalVK":true/);
      assert.match(html, /"focusCanvas":true/);
      assert.equal((html.match(/src="mobile-name.js"/g) || []).length, 1);
      assert.ok(readFileSync(join(web, 'mobile-name.js')).length > 0);
      assert.ok(readFileSync(join(web, 'arcade-name.ttf')).length > 0);
    }
    writeFileSync(join(web, 'index.html'), '<script src="index.js"></script>');
    const result = spawnSync(process.execPath, [buildScript], { cwd: folder, encoding: 'utf8' });
    assert.notEqual(result.status, 0);
    assert.match(result.stderr, /Reexporta desde Godot/);
    writeFileSync(join(folder, 'Main.gd'), 'extends Node2D');
    const future = new Date(Date.now() + 60000);
    utimesSync(join(folder, 'Main.gd'), future, future);
    const stale = spawnSync(process.execPath, [buildScript], { cwd: folder, encoding: 'utf8' });
    assert.notEqual(stale.status, 0);
    assert.match(stale.stderr, /exportacion Web esta desactualizada/);
  } finally {
    rmSync(folder, { recursive: true, force: true });
  }
});

test('build importa una exportacion reciente desde el destino configurado en Godot', () => {
  const folder = mkdtempSync(join(tmpdir(), 'invasores-external-export-'));
  try {
    const exported = join(folder, 'godot-export');
    mkdirSync(exported);
    writeFileSync(join(folder, 'Main.gd'), 'extends Node2D');
    const past = new Date(Date.now() - 60000);
    utimesSync(join(folder, 'Main.gd'), past, past);
    writeFileSync(join(folder, 'export_presets.cfg'), `export_path="${join(exported, 'index.html')}"`);
    for (const name of ['index.js', 'index.wasm', 'index.pck']) writeFileSync(join(exported, name), 'exportacion nueva');
    writeFileSync(join(exported, 'index.html'), '<html><head><script src="index.js"></script></head><body><script>const GODOT_CONFIG={"experimentalVK":false};</script></body></html>');
    const result = spawnSync(process.execPath, [buildScript], { cwd: folder, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(readFileSync(join(folder, 'web/index.pck'), 'utf8'), 'exportacion nueva');
    assert.match(readFileSync(join(folder, 'web/index.html'), 'utf8'), /"experimentalVK":true/);
    const future = new Date(Date.now() + 60000);
    utimesSync(join(folder, 'Main.gd'), future, future);
    const stale = spawnSync(process.execPath, [buildScript], { cwd: folder, encoding: 'utf8' });
    assert.notEqual(stale.status, 0);
    assert.match(stale.stderr, /exportacion Web esta desactualizada/);
  } finally {
    rmSync(folder, { recursive: true, force: true });
  }
});
