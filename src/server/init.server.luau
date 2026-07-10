--[[
	init.server.luau  (Script)
	UBICACIÓN EN STUDIO: ServerScriptService > Server
	(con Rojo se sincroniza solo; si pegas a mano, crea un Script llamado
	"Server" en ServerScriptService, pega esto, y crea el ModuleScript
	"GameState" como HIJO de ese Script)

	Este es el CEREBRO del juego. Se encarga de:
	  1. Crear los RemoteEvents (el "cable" entre servidor y cliente).
	  2. Cuando un jugador entra, arrancar su turno de noche.
	  3. Recorrer la lista de clientes uno por uno.
	  4. Mandar cada cliente al GUI del jugador y ESPERAR su decisión.
	  5. Validar la decisión (nunca confiar en el cliente) y aplicar banderas.
	  6. Al terminar la noche, elegir el final según las banderas.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- ── Módulos de datos ─────────────────────────────────────────────────
-- Los datos viven en ReplicatedStorage/Shared para editarlos fácil
-- sin tocar la lógica.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ClientesData = require(Shared:WaitForChild("ClientesData"))
local FinalesData = require(Shared:WaitForChild("FinalesData"))

-- GameState y Mapa son hijos de este mismo Script.
local GameState = require(script:WaitForChild("GameState"))
local Mapa = require(script:WaitForChild("Mapa"))

-- Levantamos la tienda ANTES de que entre nadie.
Mapa.construir()

-- ── Configuración del ritmo de la noche ──────────────────────────────
local SEGUNDOS_ANTES_DE_EMPEZAR = 4 -- pausa al entrar, para que cargue el GUI
local SEGUNDOS_ENTRE_CLIENTES = 5 -- pausa después de cada respuesta
local SEGUNDOS_LIMITE_DECISION = 120 -- si el jugador no decide, se elige la opción 1

-- ── 1. Crear los RemoteEvents ────────────────────────────────────────
-- Los creamos por código para no armar nada a mano en Studio.
-- Quedan en ReplicatedStorage/Remotos, visibles para servidor y cliente.
local remotos = Instance.new("Folder")
remotos.Name = "Remotos"
remotos.Parent = ReplicatedStorage

local function crearRemoto(nombre)
	local remoto = Instance.new("RemoteEvent")
	remoto.Name = nombre
	remoto.Parent = remotos
	return remoto
end

local remotoMostrarCliente = crearRemoto("MostrarCliente") -- servidor -> cliente
local remotoMostrarRespuesta = crearRemoto("MostrarRespuesta") -- servidor -> cliente
local remotoFinDeTurno = crearRemoto("FinDeTurno") -- servidor -> cliente
local remotoDecision = crearRemoto("TomarDecision") -- cliente -> servidor

-- ── 2. Recibir decisiones del cliente ────────────────────────────────
-- REGLA DE ORO: el servidor valida TODO lo que llega del cliente.
-- Un exploit puede mandar cualquier cosa por un RemoteEvent, así que
-- comprobamos que la decisión corresponda al cliente que de verdad
-- está en el mostrador y a una opción que de verdad existe.
remotoDecision.OnServerEvent:Connect(function(jugador, idCliente, idOpcion)
	local estado = GameState.obtener(jugador)

	-- ¿Tiene turno activo y hay un cliente esperando decisión?
	if estado == nil or estado.terminado or estado.clientePendiente == nil then
		return
	end

	-- ¿Ya había decidido? Ignoramos clicks dobles.
	if estado.decisionElegida ~= nil then
		return
	end

	local cliente = estado.clientePendiente

	-- ¿La decisión es para el cliente correcto?
	if cliente.id ~= idCliente then
		return
	end

	-- ¿La opción existe en ese cliente?
	for _, opcion in ipairs(cliente.opciones) do
		if opcion.id == idOpcion then
			-- Todo válido: guardamos la elección. El bucle de la
			-- noche (abajo) está esperando a que esto deje de ser nil.
			estado.decisionElegida = opcion.id
			return
		end
	end
	-- Si llegamos aquí, la opción no existía: se ignora.
end)

-- ── 3. Funciones de la noche ─────────────────────────────────────────

-- Arma la versión "segura" del cliente para mandarla al GUI.
-- Solo mandamos texto: nada de funciones ni banderas. El GUI no
-- necesita saber qué banderas activa cada opción (y mejor que no sepa).
local function empaquetarClienteParaGui(cliente)
	local opcionesVisibles = {}
	for _, opcion in ipairs(cliente.opciones) do
		table.insert(opcionesVisibles, {
			id = opcion.id,
			texto = opcion.texto,
		})
	end
	return {
		id = cliente.id,
		nombre = cliente.nombre,
		hora = cliente.hora,
		dialogo = cliente.dialogo,
		opciones = opcionesVisibles,
	}
end

-- Presenta UN cliente y espera la decisión del jugador.
-- Devuelve la tabla completa de la opción elegida (con banderas).
local function atenderCliente(jugador, estado, cliente)
	-- Registramos quién está en el mostrador y limpiamos decisiones viejas.
	estado.clientePendiente = cliente
	estado.decisionElegida = nil

	-- Mandamos el cliente al GUI del jugador.
	remotoMostrarCliente:FireClient(jugador, empaquetarClienteParaGui(cliente))

	-- Esperamos la decisión. task.wait en bucle "pausa" este hilo
	-- sin congelar el resto del servidor.
	local inicio = os.clock()
	while estado.decisionElegida == nil do
		task.wait(0.25)

		-- Si el jugador se fue del juego, abortamos.
		if GameState.obtener(jugador) == nil then
			return nil
		end

		-- Si tarda demasiado, elegimos la primera opción por él.
		if os.clock() - inicio > SEGUNDOS_LIMITE_DECISION then
			estado.decisionElegida = cliente.opciones[1].id
		end
	end

	-- Buscamos la tabla completa de la opción elegida.
	local opcionElegida = nil
	for _, opcion in ipairs(cliente.opciones) do
		if opcion.id == estado.decisionElegida then
			opcionElegida = opcion
			break
		end
	end

	-- Ya no hay nadie en el mostrador.
	estado.clientePendiente = nil
	estado.decisionElegida = nil

	return opcionElegida
end

-- Recorre la lista de finales y devuelve el PRIMERO cuya condición
-- se cumpla con las banderas actuales. Por eso el orden importa.
local function elegirFinal(banderas)
	for _, final in ipairs(FinalesData) do
		if final.condicion == nil or final.condicion(banderas) then
			return final
		end
	end
	-- Red de seguridad: si todos tuvieran condición y ninguna se
	-- cumpliera, devolvemos el último.
	return FinalesData[#FinalesData]
end

-- La noche completa de UN jugador, de 10 PM a 6 AM.
local function correrTurno(jugador)
	local estado = GameState.iniciar(jugador)

	-- Pausa para que el GUI del jugador alcance a construirse.
	task.wait(SEGUNDOS_ANTES_DE_EMPEZAR)

	-- Recorremos las entradas de la noche EN ORDEN.
	for _, entrada in ipairs(ClientesData) do
		-- Si el jugador se desconectó, se acabó.
		if GameState.obtener(jugador) == nil then
			return
		end

		if entrada.tipo == "evento" then
			-- EVENTO DE AMBIENTE: pasa algo en el mapa (una PISTA).
			-- No hay decisión: el jugador solo lo ve... si está atento.
			Mapa.ejecutarEvento(entrada.evento)
			task.wait(entrada.duracion or 5)
		else
			-- CLIENTE: ¿aparece esta noche? Su condición decide,
			-- usando las banderas acumuladas hasta ahora. Aquí es donde
			-- las decisiones tempranas cambian la noche.
			local apareceEstaNoche = true
			if entrada.condicion ~= nil then
				apareceEstaNoche = entrada.condicion(estado.banderas)
			end

			if apareceEstaNoche then
				-- La figura del cliente aparece frente al mostrador.
				Mapa.mostrarNPC(entrada.npc)

				local opcionElegida = atenderCliente(jugador, estado, entrada)
				if opcionElegida == nil then
					return -- el jugador se fue a media decisión
				end

				-- Aplicamos las banderas. Esta línea hace que
				-- "la noche recuerde" lo que elegiste.
				if opcionElegida.banderas ~= nil then
					GameState.marcarBanderas(jugador, opcionElegida.banderas)
				end

				-- Consecuencia inmediata en pantalla + tiempo de leerla.
				remotoMostrarRespuesta:FireClient(jugador, opcionElegida.respuesta)
				task.wait(SEGUNDOS_ENTRE_CLIENTES)

				-- El cliente se retira del mostrador.
				Mapa.quitarNPC()
			end
		end
	end

	-- Se acabaron los clientes: son las 6 AM. Elegimos el final.
	if GameState.obtener(jugador) == nil then
		return
	end
	estado.terminado = true

	local final = elegirFinal(estado.banderas)
	remotoFinDeTurno:FireClient(jugador, {
		titulo = final.titulo,
		texto = final.texto,
	})

	-- Registro en consola (Output): útil para depurar por qué salió
	-- cierto final — muestra exactamente qué banderas se marcaron.
	local lista = {}
	for nombre in pairs(estado.banderas) do
		table.insert(lista, nombre)
	end
	print("[TurnoDeNoche] banderas:", table.concat(lista, ", "))
	print("[TurnoDeNoche]", jugador.Name, "terminó con el final:", final.id)
end

-- ── 4. Conectar jugadores ────────────────────────────────────────────
Players.PlayerAdded:Connect(function(jugador)
	-- task.spawn corre el turno en su propio "hilo": si hay varios
	-- jugadores, cada quien vive su propia noche sin estorbarse.
	task.spawn(correrTurno, jugador)
end)

Players.PlayerRemoving:Connect(function(jugador)
	GameState.limpiar(jugador)
end)

print("[TurnoDeNoche] Servidor listo. Esperando empleados del turno nocturno...")
