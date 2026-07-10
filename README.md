# Turno de Noche 🌙🏪

Prototipo de un juego narrativo para Roblox. Eres el empleado del
turno nocturno (10 PM – 6 AM) de una tienda de conveniencia. Los clientes
llegan uno por uno: algunos normales, otros... no tanto. Cada cliente te
presenta **una decisión**, y tus decisiones se acumulan como *banderas*
que cambian qué pasa después en la noche y qué final obtienes.

**La tienda es un mapa 3D construido 100 % por código** — mostrador,
estantes, refrigeradores, cámara de seguridad, trastienda con un frasco
que brilla... Entre cliente y cliente ocurren **eventos de ambiente**
(un gato cruza la tienda, las luces parpadean). Esos eventos son PISTAS:
varias decisiones tienen 3 opciones y solo una es correcta — y solo
puedes estar seguro de cuál **si estabas mirando cuando pasó la pista**.
Las otras opciones son señuelos plausibles.

## Estructura del proyecto

Cada carpeta de `src/` corresponde a un lugar de Roblox Studio:

| Carpeta / archivo | Lugar en Studio | Tipo | Qué hace |
|---|---|---|---|
| `src/shared/ClientesData.luau` | `ReplicatedStorage > Shared > ClientesData` | ModuleScript | Base de datos de la noche: clientes Y eventos-pista |
| `src/shared/FinalesData.luau` | `ReplicatedStorage > Shared > FinalesData` | ModuleScript | Lista de finales y sus condiciones |
| `src/server/init.server.luau` | `ServerScriptService > Server` | Script | Cerebro: loop de la noche, RemoteEvents, validación |
| `src/server/GameState.luau` | `ServerScriptService > Server > GameState` (hijo del Script) | ModuleScript | Estado del turno por jugador (solo servidor) |
| `src/server/Mapa.luau` | `ServerScriptService > Server > Mapa` (hijo del Script) | ModuleScript | Construye la tienda 3D + NPCs + eventos de ambiente |
| `src/client/init.client.luau` | `StarterPlayer > StarterPlayerScripts > Client` | LocalScript | GUI creada 100 % por código |

**Regla de arquitectura:** todo el estado vive en el servidor. El cliente
solo dibuja lo que el servidor le manda y le avisa qué botón se pulsó.
El servidor valida cada decisión — nunca confía en el cliente. El mapa
y sus eventos también viven en el servidor: se replican solos a todos.

## Cómo probar

### Opción A: con Rojo (recomendada — este repo ya está configurado)

1. Instala [Rojo](https://rojo.space/docs/v7/getting-started/installation/)
   y su plugin de Studio.
2. En la terminal, dentro de esta carpeta:
   ```bash
   rojo serve
   ```
3. Abre cualquier place en Roblox Studio → botón **Rojo → Connect**.
4. Los scripts aparecen solos en su lugar. Pulsa **▶ Play**.

### Opción B: pegar a mano (sin instalar nada)

1. Abre Roblox Studio → **New → Baseplate**.
2. En el panel *Explorer* (si no lo ves: View → Explorer):

   **ReplicatedStorage:**
   - Clic derecho en `ReplicatedStorage` → Insert Object → **Folder**. Nómbrala `Shared`.
   - Clic derecho en `Shared` → Insert Object → **ModuleScript**. Nómbralo `ClientesData`.
     Borra su contenido y pega el de `src/shared/ClientesData.luau`.
   - Repite: otro **ModuleScript** llamado `FinalesData` con el contenido
     de `src/shared/FinalesData.luau`.

   **ServerScriptService:**
   - Clic derecho en `ServerScriptService` → Insert Object → **Script**. Nómbralo `Server`.
     Pega el contenido de `src/server/init.server.luau`.
   - Clic derecho en ese Script `Server` → Insert Object → **ModuleScript**
     (queda como HIJO del Script). Nómbralo `GameState`.
     Pega el contenido de `src/server/GameState.luau`.
   - Otro **ModuleScript** hijo del mismo Script `Server`. Nómbralo `Mapa`.
     Pega el contenido de `src/server/Mapa.luau`.

   **StarterPlayerScripts:**
   - En `StarterPlayer > StarterPlayerScripts`: clic derecho → Insert Object →
     **LocalScript**. Nómbralo `Client`.
     Pega el contenido de `src/client/init.client.luau`.

3. Pulsa **▶ Play**. Espera ~4 segundos y llegará el primer cliente.

### Qué deberías ver

- Apareces DETRÁS del mostrador de una tienda 24 hrs de noche: estantes
  con productos, refrigeradores que brillan, cámara de seguridad con
  lente rojo, trastienda con un frasco verde que no deberías mirar tanto.
- Panel oscuro estilo novela visual en la parte baja de la pantalla.
- El diálogo aparece letra por letra (efecto máquina de escribir).
- Cada cliente llega como figura al mostrador. 2 o 3 botones por decisión.
- **Vigila la tienda entre clientes**: un gato blanco cruza hacia la
  trastienda (~10:50 PM) y las luces parpadean (~2:30 AM). Esas pistas
  te dicen qué opción es la correcta con Elvira y con el encapuchado.
- 6–7 clientes según tus decisiones (el doble del chico solo aparece
  si ayudaste al primero).
- Al final: fade a negro y tu final del turno.
- En la ventana *Output* (View → Output) el servidor imprime las
  banderas que marcaste y qué final obtuviste — útil para entender
  por qué te tocó ese final.

### El truco de diseño: pistas y señuelos

| Evento (pista) | Cuándo | Decisión que desbloquea |
|---|---|---|
| Gato blanco cruza a la trastienda | Después del 1er cliente | Elvira: "¿ha visto a mi gato?" → la opción **trastienda** es la única verdad. "Bosque" y "no vi nada" son señuelos. |
| Las luces parpadean | Antes del encapuchado | Encapuchado: "apaga la cámara" → puedes **mentirle** ("está descompuesta desde el apagón") y salvarte sin apagar nada. Solo se te ocurre si viste el apagón. |

Para agregar una pista nueva: crea el efecto en `Mapa.luau` (tabla
`eventos`), y agrega `{ tipo = "evento", evento = "tu_id", duracion = N }`
en la posición deseada de `ClientesData.luau`.

## Cómo funciona por dentro (para aprender)

```
 SERVIDOR                                        CLIENTE (GUI)
 ────────                                        ─────────────
 Recorre ClientesData en orden
 ¿entrada tipo "evento"? ── sí → Mapa.ejecutarEvento()  (pista en el mapa 3D)
        │ no: es cliente
 ¿cliente.condicion(banderas)? ─ no → lo salta
        │ sí
        ▼
 Mapa.mostrarNPC() (figura al mostrador)
 FireClient("MostrarCliente") ────────────────▶  dibuja diálogo + botones
                                                      │ jugador pulsa botón
 valida idCliente + idOpcion  ◀──────────────── FireServer("TomarDecision")
        │ válido
        ▼
 aplica opcion.banderas al GameState
 FireClient("MostrarRespuesta") ──────────────▶  muestra consecuencia
 Mapa.quitarNPC()
        │ (siguiente entrada...)
        ▼
 fin de la lista → recorre FinalesData,
 primer final cuya condición cumpla
 FireClient("FinDeTurno") ────────────────────▶  pantalla de final
```

- **Banderas** = tabla `{ nombre = true }` en el servidor. La memoria de la noche.
- **RemoteEvents** = el único puente entre servidor y cliente. El servidor
  los crea por código al arrancar (carpeta `ReplicatedStorage > Remotos`).
- **Anti-trampas**: el cliente solo recibe texto (nunca las banderas ni las
  condiciones), y el servidor rechaza decisiones inválidas o duplicadas.

## Cómo agregar un cliente nuevo

Abre `ClientesData.luau` y agrega una entrada a la tabla. Nada más.

```lua
{
    id = "repartidor",                    -- único, sin espacios
    nombre = "Repartidor empapado",
    hora = "3:15 AM",
    dialogo = "Traigo una caja para esta dirección... pero la tienda no pidió nada.",
    -- OPCIONAL: solo aparece si se cumplen ciertas banderas
    condicion = function(banderas)
        return banderas.apagaste_camara == true
    end,
    opciones = {
        {
            id = "aceptar",
            texto = "Firmar y recibir la caja",
            respuesta = "La caja pesa... y algo se mueve adentro.",
            banderas = { aceptaste_caja = true },
        },
        {
            id = "rechazar",
            texto = "Rechazar el paquete",
            respuesta = "El repartidor asiente aliviado. \"Buena elección\", susurra.",
            banderas = { rechazaste_caja = true },
        },
    },
},
```

El orden en la tabla = orden en que llegan los clientes.

## Cómo agregar un final nuevo

Abre `FinalesData.luau` y agrega una entrada **antes del final por defecto**
(el último, que no tiene condición). El primer final cuya condición se
cumpla es el que gana, así que pon los más específicos arriba.

```lua
{
    id = "coleccionista",
    titulo = "FINAL: EL COLECCIONISTA",
    texto = "Aceptaste la caja. Ahora eres parte de la colección.",
    condicion = function(banderas)
        return banderas.aceptaste_caja == true
    end,
},
```

## Ajustar el ritmo de la noche

Arriba de `init.server.luau`:

```lua
local SEGUNDOS_ANTES_DE_EMPEZAR = 4    -- pausa inicial
local SEGUNDOS_ENTRE_CLIENTES = 5      -- pausa tras cada respuesta
local SEGUNDOS_LIMITE_DECISION = 120   -- timeout: se elige la opción 1
```

## Ideas para crecer el prototipo

- Sonido ambiental y "ding" de puerta (`SoundService`, IDs de la librería de Roblox).
- Modelo 3D de la tienda con mostrador (ahora todo es GUI).
- Reloj visible que avance de 10 PM a 6 AM con la cantidad de clientes.
- Más de 2 opciones por cliente (el GUI ya lo soporta — es una lista).
- Guardar el mejor final con `DataStoreService`.
