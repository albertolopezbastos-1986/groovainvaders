import { existsSync, readFileSync, readdirSync, writeFileSync, copyFileSync, statSync, mkdirSync, utimesSync } from 'node:fs';
import { join, dirname, isAbsolute, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

// El editor abierto puede conservar otro destino, por ejemplo D:/beto/index.html.
// Aprovechar esa exportacion local reciente sin pedir que se exporte dos veces.
const sources = ['Main.gd', 'OnlineScores.gd', 'Main.tscn'];
const sourceTime = Math.max(0, ...sources.filter(existsSync).map((name) => statSync(name).mtimeMs));
if (existsSync('export_presets.cfg')) {
  const configured = readFileSync('export_presets.cfg', 'utf8').match(/^export_path="([^"]+)"/m)?.[1];
  let exportedHtml = configured;
  if (process.platform === 'linux' && /^[A-Za-z]:\//.test(exportedHtml || '')) {
    exportedHtml = `/mnt/${exportedHtml[0].toLowerCase()}${exportedHtml.slice(2)}`;
  }
  if (exportedHtml && isAbsolute(exportedHtml) && exportedHtml.endsWith('/index.html') && resolve(exportedHtml) !== resolve('web/index.html')) {
    const exportedPack = join(dirname(exportedHtml), 'index.pck');
    if (existsSync(exportedHtml) && existsSync(exportedPack)) {
      const exportedTime = statSync(exportedPack).mtimeMs;
      const currentTime = existsSync('web/index.pck') ? statSync('web/index.pck').mtimeMs : 0;
      if (exportedTime >= sourceTime && exportedTime > currentTime) {
        mkdirSync('web', { recursive: true });
        for (const name of readdirSync(dirname(exportedHtml))) {
          if (!name.startsWith('index.')) continue;
          const source = join(dirname(exportedHtml), name);
          const info = statSync(source);
          if (!info.isFile()) continue;
          const target = join('web', name);
          copyFileSync(source, target);
          utimesSync(target, info.atime, info.mtime);
        }
        console.log(`Exportacion reciente copiada desde ${dirname(exportedHtml)} a web/.`);
      }
    }
  }
}

if (!existsSync('web/index.html')) {
  throw new Error('Primero exporta el juego desde Godot: Web -> web/index.html. Ver PUBLICAR_NETLIFY.md.');
}
for (const extension of ['.wasm', '.pck', '.js']) {
  if (!readdirSync('web').some((name) => name.endsWith(extension))) {
    throw new Error(`Faltan archivos ${extension} en web/. Exporta todos los archivos de Godot juntos.`);
  }
}
// Un HTML nuevo no actualiza el codigo GDScript empaquetado dentro del PCK.
const packFiles = readdirSync('web').filter((name) => name.endsWith('.pck'));
const packTime = Math.max(...packFiles.map((name) => statSync(join('web', name)).mtimeMs));
for (const source of sources) {
  if (existsSync(source) && statSync(source).mtimeMs > packTime) {
    throw new Error(`La exportacion Web esta desactualizada (${source} es mas nuevo que el .pck). En Godot: Proyecto > Exportar > Web > Exportar proyecto a web/index.html; despues repeti el deploy.`);
  }
}
let html = readFileSync('web/index.html', 'utf8');
for (const match of html.matchAll(/<script[^>]+src=["']([^"']+)["']/g)) {
  if (!/^https?:/.test(match[1]) && !existsSync(join('web', match[1]))) {
    throw new Error(`El HTML referencia un script ausente: ${match[1]}`);
  }
}
// Godot guarda esta opcion en el HTML exportado. Cambiar solo el preset no
// actualiza una exportacion existente: habilitarla tambien al publicar.
if (!/"experimentalVK"\s*:\s*(true|false)\b/.test(html)) {
  throw new Error('No se encontro la configuracion del teclado Web. Reexporta desde Godot a web/index.html.');
}
let updatedHtml = html.replace(/("experimentalVK"\s*:\s*)false\b/g, '$1true');
if (updatedHtml !== html) {
  console.log('Teclado del celular habilitado en la exportacion Web.');
}
copyFileSync(fileURLToPath(new URL('./mobile-name.js', import.meta.url)), 'web/mobile-name.js');
copyFileSync(fileURLToPath(new URL('../assets/fonts/PressStart2P-Regular.ttf', import.meta.url)), 'web/arcade-name.ttf');
if (!updatedHtml.includes('src="mobile-name.js"')) {
  updatedHtml = updatedHtml.replace('</head>', '<script src="mobile-name.js" defer></script>\n</head>');
}
if (updatedHtml !== html) writeFileSync('web/index.html', updatedHtml);
writeFileSync('web/deployment.json', JSON.stringify({
  built_at: new Date().toISOString(),
  game_sha256: createHash('sha256').update(readFileSync(join('web', packFiles[0]))).digest('hex'),
  mobile_input_sha256: createHash('sha256').update(readFileSync('web/mobile-name.js')).digest('hex')
}));
console.log('Exportacion Web lista. Netlify empaquetara las funciones con el juego.');
