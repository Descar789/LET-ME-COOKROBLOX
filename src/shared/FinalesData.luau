--[[
	FinalesData.luau  (ModuleScript)
	UBICACIÓN EN STUDIO: ReplicatedStorage > Shared > FinalesData

	Aquí viven los FINALES del turno. Cuando la noche termina, el servidor
	recorre esta lista EN ORDEN y se queda con el PRIMER final cuya
	condición se cumpla. Por eso el orden importa: los finales más
	específicos van arriba y el final "normal" va al último sin condición.

	PARA AGREGAR UN FINAL NUEVO: agrega una entrada con su condición y
	colócala antes del final por defecto.

	Estructura de cada final:
	  id        -> texto único.
	  titulo    -> título grande que ve el jugador.
	  texto     -> descripción del final.
	  condicion -> (OPCIONAL) función que recibe las banderas y devuelve
	               true si este final aplica. Sin condición = siempre
	               aplica (úsalo solo para el final por defecto).
]]

local FinalesData = {

	-- Final 1: el más específico. Entregaste tu identidad.
	{
		id = "reemplazado",
		titulo = "FINAL: EL REEMPLAZADO",
		texto = "Le entregaste el turno... y con él, tu lugar en el mundo. Nadie nota la diferencia. Tú tampoco, ya. Mañana atenderás el turno de noche. Y el que sigue. Y el que sigue.",
		condicion = function(banderas)
			return banderas.entregaste_turno == true
		end,
	},

	-- Final 2: te metiste en cosas turbias.
	{
		id = "complice",
		titulo = "FINAL: CÓMPLICE DE LO OSCURO",
		texto = "Apagaste la cámara y entregaste el frasco sin preguntar. Al salir, encuentras un sobre con tu nombre... escrito con una letra que reconoces: la tuya. Dentro, solo dice: \"Bienvenido al verdadero turno.\"",
		condicion = function(banderas)
			return banderas.apagaste_camara == true and banderas.entregaste_frasco == true
		end,
	},

	-- Final 3: el bueno. Atento, honesto y amable toda la noche.
	-- Nota: dijiste_verdad_elvira solo se logra si VISTE al gato cruzar
	-- (evento del mapa) — este final premia la atención, no la suerte.
	{
		id = "protegido",
		titulo = "FINAL: PROTEGIDO POR EL GATO",
		texto = "Viste lo que otros no ven, fuiste honesto con Elvira, generoso con el chico y alimentaste al gato. Al amanecer, encuentras una vela blanca encendida junto a la caja y una nota: \"Esta tienda tiene muchos empleados. Pocos sobreviven al aburrimiento. Menos aún a la noche. Usted sobrevivió a ambos. — E.\"",
		condicion = function(banderas)
			return banderas.dijiste_verdad_elvira == true
				and (banderas.fiaste_sopa == true or banderas.pagaste_sopa == true)
				and banderas.alimentaste_gato == true
		end,
	},

	-- Final 4: mentiste y encima maltrataste al gato. Mal plan.
	{
		id = "marcado",
		titulo = "FINAL: MARCADO",
		texto = "Le mentiste a Elvira y echaste a su gato. Al cerrar la caja, ves tu reflejo en el vidrio... pero tu reflejo tiene un ojo de cada color. Y sonríe antes que tú.",
		condicion = function(banderas)
			return banderas.mentiste_elvira == true and banderas.sacaste_gato == true
		end,
	},

	-- Final por defecto: SIEMPRE va al último y SIN condición.
	{
		id = "amanecer",
		titulo = "FINAL: AMANECER... ¿NORMAL?",
		texto = "Son las 6:00 AM. Sobreviviste al turno de noche. El sol sale, los clientes raros se fueron y todo parece en orden. Casi. En el registro de la cámara hay 9 clientes... pero tú solo atendiste a 7.",
		condicion = nil,
	},
}

return FinalesData
