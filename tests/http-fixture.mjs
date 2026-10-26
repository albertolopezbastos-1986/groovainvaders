// Backend en memoria SOLO para las pruebas de conexion HTTP de Godot.
import { createServer } from 'node:http';
import { createHandler } from '../netlify/lib/score-service.mjs';
import { MemoryStore } from './memory-store.mjs';

const store = new MemoryStore();
const read = createHandler('read', () => store);
const write = createHandler('write', () => store);
const server = createServer(async (incoming, outgoing) => {
  try {
    const chunks = [];
    for await (const chunk of incoming) chunks.push(chunk);
    const url = `http://127.0.0.1:${server.address().port}${incoming.url}`;
    const request = new Request(url, {
      method: incoming.method, headers: incoming.headers,
      ...(incoming.method === 'POST' ? { body: Buffer.concat(chunks) } : {})
    });
    const response = incoming.url.startsWith('/offline/')
      ? Response.json({ error: 'Offline de prueba' }, { status: 503 })
      : await (incoming.url.startsWith('/api/submit-score') ? write : read)(request);
    outgoing.writeHead(response.status, Object.fromEntries(response.headers));
    outgoing.end(Buffer.from(await response.arrayBuffer()));
  } catch (error) {
    outgoing.writeHead(500);
    outgoing.end(error.message);
  }
});
server.listen(0, '127.0.0.1', () => console.log(`http://127.0.0.1:${server.address().port}`));
