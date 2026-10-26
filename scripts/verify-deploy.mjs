import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export async function verifyDeployment(url, expected, fetcher = fetch) {
  const base = url.replace(/\/$/, '');
  const options = { cache: 'no-store', signal: AbortSignal.timeout(15000) };
  const manifest = await fetcher(`${base}/deployment.json?t=${Date.now()}`, options);
  if (!manifest.ok) throw new Error('El sitio no tiene deployment.json: se publico una carpeta diferente de web/ o una version anterior.');
  const deployed = await manifest.json();
  if (deployed.game_sha256 !== expected.game_sha256 || deployed.mobile_input_sha256 !== expected.mobile_input_sha256) {
    throw new Error('La version publicada no coincide con el build local.');
  }
  const api = await fetcher(`${base}/api/scores`, options);
  if (api.status === 404) throw new Error('Faltan las Functions del ranking. Publica desde la raiz con npm run deploy, no desde Drop.');
  if (!api.ok) throw new Error(`El ranking responde HTTP ${api.status}. Revisa los logs de la funcion scores.`);
  const body = await api.json();
  if (!Array.isArray(body.scores)) throw new Error('El ranking no devuelve la tabla esperada.');
  const page = await fetcher(`${base}/?verify=${Date.now()}`, options);
  const html = await page.text();
  if (!page.ok || !html.includes('src="mobile-name.js"') || !/"experimentalVK"\s*:\s*true/.test(html)) {
    throw new Error('El HTML publicado no tiene el teclado nativo actualizado.');
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const expected = JSON.parse(readFileSync('web/deployment.json', 'utf8'));
    await verifyDeployment(process.argv[2] || 'https://groovaipa.netlify.app', expected);
    console.log('Publicacion verificada: version correcta, campo nativo incluido y ranking online accesible.');
  } catch (error) {
    console.error(`Verificacion fallida: ${error.message}`);
    process.exitCode = 1;
  }
}
