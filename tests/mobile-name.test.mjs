import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

test('campo nativo conserva foco al redimensionar, sincroniza el nombre y acepta Enter una sola vez', () => {
  const elements = [];
  const gestures = {};
  let focusCount = 0;
  const canvas = { getBoundingClientRect: () => ({ left: 10, top: 20, width: 390, height: 844 }) };
  const document = {
    head: { appendChild() {} }, body: { appendChild(element) { elements.push(element); } },
    activeElement: null, fullscreenElement: null,
    addEventListener(name, callback) { gestures[name] = callback; },
    getElementById: (id) => id === 'canvas' ? canvas : null,
    createElement() {
      return { style: {}, value: '', events: {}, setAttribute() {},
        addEventListener(name, callback) { this.events[name] = callback; },
        focus() { focusCount++; document.activeElement = this; },
        blur() { if (document.activeElement === this) document.activeElement = null; }
      };
    }
  };
  const window = {};
  const script = readFileSync('scripts/mobile-name.js', 'utf8');
  const context = { window, document };
  runInNewContext(script, context);
  const field = elements[0];
  assert.equal(field.type, 'text');
  assert.equal(field.maxLength, 12);
  const state = { session: 'run1', value: '', visible: true, x: 20, y: 200, w: 500, h: 56, width: 540, height: 1169 };
  window.PixelNameInput.update(state);
  assert.equal(document.activeElement, field, 'Enfoca automaticamente al mostrar Game Over');
  assert.equal(focusCount, 1);
  field.value = 'BETO';
  const result = window.PixelNameInput.update({ ...state, height: 900 });
  assert.equal(result.value, 'BETO');
  assert.equal(document.activeElement, field);
  assert.equal(field.style.display, 'block');
  assert.equal(focusCount, 1, 'Redimensionar no vuelve a enfocar');
  document.activeElement = null;
  let captured = false;
  gestures.touchend({ target: canvas, changedTouches: [{ clientX: 40, clientY: 220 }], preventDefault() {}, stopImmediatePropagation() { captured = true; } });
  assert.equal(document.activeElement, field, 'Tocar el campo enfoca dentro del gesto nativo');
  assert.ok(captured, 'El canvas no recibe el toque del campo');
  let prevented = false;
  field.events.keydown({ key: 'Enter', isComposing: false, stopPropagation() {}, preventDefault() { prevented = true; } });
  assert.ok(prevented);
  assert.equal(window.PixelNameInput.update(state).submitted, true);
  assert.equal(window.PixelNameInput.update(state).submitted, false);
  window.PixelNameInput.hide();
  assert.equal(field.style.display, 'none');
  window.PixelNameInput.update({ ...state, session: 'run2' });
  assert.equal(field.value, '');
  runInNewContext(script, context);
  assert.equal(elements.length, 1);
});
