--[[
	GameState.luau  (ModuleScript)
	UBICACIÓN EN STUDIO: ServerScriptService > TurnoDeNoche > GameState
	(es HIJO del Script principal del servidor)

	Este módulo guarda TODO el estado del turno de cada jugador.
	Vive únicamente en el servidor: el cliente jamás puede leerlo ni
	modificarlo directamente. El cliente solo se entera de lo que el
	servidor decide mandarle por RemoteEvent.

	¿Por qué en el servidor? Porque en Roblox todo lo que está en el
	cliente puede ser manipulado por exploits. Si las banderas vivieran
	en el cliente, un tramposo podría darse el final que quisiera.

	Estado que guardamos por jugador:
	  banderas         -> tabla { nombre_bandera = true } con las
	                      decisiones tomadas. Es la memoria de la noche.
	  clientePendiente -> el cliente que está esperando una decisión
	                      (nil si no hay ninguno en el mostrador).
	  decisionElegida  -> id de la opción que eligió el jugador
	                      (nil hasta que decide).
	  terminado        -> true cuando la noche ya acabó.
]]

local GameState = {}

-- Aquí viven los estados de todos los jugadores conectados.
-- La llave es el objeto Player, el valor es su tabla de estado.
local estados = {}

-- Crea el estado inicial de un jugador cuando empieza su turno.
function GameState.iniciar(jugador)
	estados[jugador] = {
		banderas = {},
		clientePendiente = nil,
		decisionElegida = nil,
		terminado = false,
	}
	return estados[jugador]
end

-- Devuelve el estado de un jugador (o nil si no tiene turno activo).
function GameState.obtener(jugador)
	return estados[jugador]
end

-- Enciende un grupo de banderas en el estado del jugador.
-- 'nuevasBanderas' es una tabla como { fiaste_sopa = true }.
function GameState.marcarBanderas(jugador, nuevasBanderas)
	local estado = estados[jugador]
	if estado == nil then
		return
	end
	for nombre, valor in pairs(nuevasBanderas) do
		estado.banderas[nombre] = valor
	end
end

-- Borra el estado cuando el jugador se va del juego.
-- Importante para no dejar basura en memoria.
function GameState.limpiar(jugador)
	estados[jugador] = nil
end

return GameState
