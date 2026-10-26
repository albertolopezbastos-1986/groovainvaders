# Publicar el ranking mundial

El juego usa un ranking compartido en Netlify Functions + Netlify Blobs. El disparo del jugador ahora es silencioso; siguen la musica, los disparos aliens y sus explosiones.

Esta entrega prepara el codigo y la configuracion. Todavia hay que exportar el juego actualizado y publicarlo en tu sitio de Netlify. Los archivos `InvasoresGroova.*` que estaban en la raiz son una exportacion anterior y no se usan para publicar esta version.

## 1. Exportar el juego actualizado

1. Abri este proyecto en Godot 4 Standard y espera a que importe `OnlineScores.gd` y los recursos.
2. En **Proyecto > Exportar > Web**, instala las plantillas si falta hacerlo.
3. Exporta como **`web/index.html`** dentro de este proyecto. La ruta ya esta configurada en `export_presets.cfg`; crea la carpeta `web` si hace falta.
4. Conserva todos los archivos que genera Godot en esa carpeta: HTML, JS, WASM, PCK y cualquier archivo adicional.

La exportacion usa Compatibility y no usa threads. El teclado virtual experimental de Web esta activado para el campo del nombre. Comproba su funcionamiento en el navegador de tu celular.

`npm run build` tambien activa `experimentalVK` en el HTML exportado. Esto corrige exportaciones que quedaron con el teclado desactivado aunque se haya cambiado el preset de Godot. No hace falta modificar el HTML a mano.

Si el editor sigue exportando a una ruta absoluta como `D:/beto/index.html`, el build local reconoce ese destino en `export_presets.cfg` y copia a `web/` una exportacion mas reciente que los scripts. Tambien reconoce unidades Windows desde WSL. Esto no reemplaza exportar desde Godot cuando se modifica el juego. En un build remoto de Git esa carpeta local no existe: en ese caso `web/` debe estar incluida en el repositorio como se explica mas abajo.

En celulares Web, el campo del nombre utiliza un input HTML nativo sobre el campo del juego para que el toque abra directamente el teclado del navegador. El build incluye `mobile-name.js` y `arcade-name.ttf` automaticamente. Este cambio requiere **reexportar el juego actualizado** antes del build; publicar solo el HTML anterior no actualiza la logica del campo. En pantalla completa, Game Over sale de ese modo para permitir el editor nativo. El nombre conserva el limite de 12 caracteres y Enter permite guardarlo.

Al entrar en Game Over se intenta enfocar automaticamente el nombre. Algunos navegadores moviles solo permiten abrir el teclado como respuesta a un toque: el campo captura ese toque antes del canvas y enfoca dentro del mismo gesto. El build rechaza un `.pck` anterior a los scripts para evitar publicar la logica vieja aunque el HTML ya este actualizado.

En Web, el juego usa automaticamente el dominio desde el que se abre. No necesitas escribir una URL ni poner claves de API en GDScript.

## 2. Publicar con Netlify CLI

Usa Node.js 22 o superior. Abri una terminal en la carpeta de este proyecto y ejecuta:

```sh
npm ci
npm test
npm run build
npx netlify-cli login
npx netlify-cli link
```

En `link`, selecciona **tu sitio existente**, el mismo que usabas con Drop. Esto permite conservar su direccion. A continuacion, publica:

```sh
npm run deploy
```

`netlify.toml` publica solamente `web/` y empaqueta las funciones desde `netlify/functions/`. El codigo del servidor y `node_modules` no se sirven como archivos publicos. Arrastrar solamente `web/` a Drop no instala estas funciones.

`npm run deploy` indica explicitamente las carpetas del juego y de las funciones, y luego verifica `https://groovaipa.netlify.app`: compara la version del PCK y del campo nativo con el build local y consulta `/api/scores`. Si el sitio tiene HTML viejo o faltan las Functions, termina con un error concreto en vez de dar la publicacion por verificada. Para repetir solo la comprobacion: `npm run verify:deploy`. La ruta del ranking es `/api/scores`, en minusculas.

No se necesitan tokens en el codigo ni credenciales de Blobs en el navegador. El SDK del servidor obtiene las credenciales del sitio en el entorno de Netlify. No copies tokens de tu cuenta a Godot.

## 3. Comprobar la version publicada

1. Abri `https://groovaipa.netlify.app/api/scores`. Debe devolver `{"scores":[]}` si no hay resultados, o una lista con los puntajes existentes. Un 404 indica que las funciones no se publicaron.
2. Juga una partida, ingresa tu nombre y pulsa **GUARDAR PUNTAJE**. Debe aparecer **PUNTAJE GUARDADO ONLINE**.
3. Abri el mismo sitio desde otro dispositivo y termina una partida. Su Top 10 debe incluir los mismos resultados. Usa **ACTUALIZAR RANKING** para consultar nuevamente.
4. Si tu partida esta entre las diez mejores, aparece en verde con `>`; se identifica por partida, no por nombre, por lo que dos jugadores pueden usar el mismo nombre.
5. Desconecta la red antes de guardar: debe permitir reintentar o volver a jugar. Reintenta con red sin cambiar de partida para comprobar que no duplica el resultado.

La tabla se consulta al terminar y al guardar; no usa polling permanente. La fecha UTC se conserva en el servidor y aparece como ayuda al pasar el mouse sobre una fila.

## Desarrollo local y Godot desktop

Despues de exportar a `web/` y vincular el sitio, ejecuta:

```sh
npm run dev
```

Abri `http://localhost:8888`. Netlify Dev ejecuta las funciones y usa Blobs local. Estos datos no son los de produccion.

En el editor de Godot o una version desktop, el cliente usa `http://localhost:8888` por defecto. Para usar el sitio publicado, agrega esta propiedad String a los ajustes de proyecto, o este bloque a `project.godot`:

```ini
[ranking]

api_base_url="https://groovaipa.netlify.app"
```

Dejala vacia para que Web use automaticamente su propio origen y desktop use localhost. No pongas `/api` ni `/index.html` en esta URL. En Web se usa el mismo origen: otro dominio no esta habilitado por CORS.

## Publicar mediante Git

Tambien podes conectar el repositorio al mismo sitio de Netlify. Se usa **`npm run build`** como comando y **`web`** como carpeta de publicacion; `netlify.toml` ya lo establece.

Este flujo necesita tener la exportacion actualizada en el repositorio, porque el build no instala Godot. `web/` esta ignorada para el flujo CLI; si elegis Git, agregala expresamente con `git add -f web` y confirma esos archivos junto con los scripts, `package.json`, `package-lock.json` y `netlify.toml`. Reexporta y actualiza `web/` cuando cambie el juego.

## Persistencia y concurrencia

- El store de produccion se llama **`invasores-world-v1`**. Es un store del sitio y sobrevive a nuevas publicaciones en ese mismo sitio. No cambies el nombre ni crees otro sitio si queres conservar la tabla.
- Los previews y desarrollo usan **`invasores-world-test-v1`** y no modifican produccion. El entorno se obtiene de `context.deploy.context` en tiempo de ejecucion.
- Cada partida usa un id aleatorio de 128 bits. `submissions/<id>` conserva `{id,name,score,date}` con fecha del servidor y creacion condicional `onlyIfNew`.
- Cada resultado tiene tambien una clave inmutable en `rank/`, ordenada por puntuacion invertida, fecha e id. No se hace leer-modificar-sobrescribir de un archivo global `top10.json`.
- Dos jugadores simultaneos escriben claves diferentes. Si se corta la conexion entre el registro y el indice, reintentar la misma partida completa el indice. El servidor no devuelve exito hasta confirmar ambos registros.
- Repetir el mismo id y datos devuelve el resultado existente; cambiar nombre o puntos para ese id devuelve 409. El cliente conserva los mismos datos mientras reintenta y bloquea doble clic mientras espera.
- Se conserva el historial completo. GET lista las claves del indice y descarga solo los diez registros ganadores. Listar claves crece con el historial: sirve como base para un arcade pequeno; para un historial masivo conviene una base de datos con consultas indexadas.
- El ranking local anterior no se migra ni se mezcla con el mundial. `ScoreStore.gd` queda como codigo anterior sin uso en la nueva version.

## Validacion y proteccion basica

El servidor limita el cuerpo a 1 KB, valida id hexadecimal, nombre de 1 a 12 caracteres y puntaje entero entre 0 y 9.999.990, multiplo de 10. Rechaza campos extras y no acepta fechas del cliente. Los nombres admiten letras, numeros, espacios, punto, guion y guion bajo; se normalizan a mayusculas.

Los endpoints tienen limites nativos de Netlify por IP y dominio: **10 envios/minuto** y **60 consultas/minuto**, incluyendo las rutas alternativas de Functions. No usa contadores en memoria que se pierdan entre instancias. Los limites de Netlify pueden tardar unos segundos en aplicarse.

El POST rechaza origenes web ajenos y solo acepta JSON; las respuestas no habilitan CORS externo. El cliente tiene timeout de 12 segundos y no reintenta automaticamente en bucle. Ante una falla puede reintentar manualmente o jugar otra partida sin esperar.

Esto es proteccion basica contra abuso y duplicados, no un sistema antitrampas: el puntaje se calcula en el cliente y alguien que modifique el juego puede intentar falsificarlo dentro de los limites. Un ranking competitivo con premios requeriria validacion de partidas en servidor.

Functions, Blobs y las descargas del juego consumen los recursos de tu plan de Netlify. Esta implementacion no requiere otro proveedor de base de datos; consulta los limites y el consumo de tu cuenta antes de asumir que el uso es ilimitado.

## Pruebas

```sh
npm test
```

Incluye 100 envios simultaneos, reintentos concurrentes, reparacion tras corte, empates, validacion y errores HTTP. Usa un doble atomico en memoria del contrato de Blobs; no modifica el sitio real.

Con `godot` disponible en PATH, y los recursos importados:

```sh
npm run test:online
```

Inicia un servidor de prueba local y comprueba el HTTP real de Godot, dos clientes, Game Over, guardado con Enter, errores, resaltado y medidas de la tabla en celular. Se puede indicar otro ejecutable con la variable `GODOT_BIN`. El test usa datos aislados y no publica nada.

Falta la comprobacion final en tu sitio y en un celular real: el teclado virtual y el limite nativo de Netlify no se pueden verificar con el servidor de prueba.

## Referencias oficiales

- [Netlify Blobs: stores, consistencia y escrituras condicionales](https://docs.netlify.com/build/data-and-storage/netlify-blobs/)
- [Netlify Functions: contexto de deploy y configuracion](https://docs.netlify.com/build/functions/api/)
- [Rate limiting de Netlify](https://docs.netlify.com/manage/security/secure-access-to-sites/rate-limiting/)
- [Publicaciones con Netlify](https://docs.netlify.com/deploy/create-deploys/)
- [Exportar Godot a Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
