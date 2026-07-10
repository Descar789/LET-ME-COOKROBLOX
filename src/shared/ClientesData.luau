--[[
	ClientesData.luau  (ModuleScript)
	UBICACIÓN EN STUDIO: ReplicatedStorage > Shared > ClientesData

	Esta es la "base de datos" de clientes de la noche.
	El servidor la recorre en orden y presenta cada cliente al jugador.

	PARA AGREGAR UN CLIENTE NUEVO: solo agrega una entrada más a la tabla.
	No hay que tocar la lógica del servidor ni del cliente.

	Estructura de cada cliente:
	  id          -> texto único, sirve para identificarlo internamente.
	  nombre      -> lo que ve el jugador como nombre del cliente.
	  hora        -> hora ficticia a la que aparece (solo se muestra en pantalla).
	  dialogo     -> lo que dice el cliente al llegar al mostrador.
	  condicion   -> (OPCIONAL) función que recibe la tabla de banderas y
	                 devuelve true/false. Si devuelve false, este cliente
	                 NO aparece esta noche. Si no existe, siempre aparece.
	  opciones    -> lista de decisiones posibles. Cada opción tiene:
	      id        -> texto único dentro del cliente.
	      texto     -> lo que dice el botón.
	      respuesta -> lo que pasa después de elegir (se muestra en pantalla).
	      banderas  -> tabla de banderas que se ENCIENDEN al elegir esta
	                   opción. Ejemplo: { fiaste_sopa = true }.
	                   Estas banderas afectan clientes futuros y el final.
]]

local ClientesData = {

	-- ═══════════════ CLIENTE 1: normal ═══════════════
	{
		id = "chico_sopa",
		nombre = "Chico con sudadera",
		hora = "10:30 PM",
		dialogo = "Oye... quiero esta sopa instantánea pero me faltan 8 pesos. Te juro que mañana te los traigo. ¿Me la fías?",
		opciones = {
			{
				id = "fiar",
				texto = "Fiarle la sopa",
				respuesta = "El chico sonríe, toma la sopa y sale corriendo. \"¡Mañana vengo, lo juro!\"",
				banderas = { fiaste_sopa = true },
			},
			{
				id = "negar",
				texto = "Negarle la sopa",
				respuesta = "El chico deja la sopa en el mostrador y se va sin decir nada. Afuera hace frío.",
				banderas = { negaste_sopa = true },
			},
		},
	},

	-- ═══════════════ CLIENTE 2: extraño ═══════════════
	{
		id = "senora_velas",
		nombre = "Señora Elvira",
		hora = "11:15 PM",
		dialogo = "Buenas noches, joven. Trece velas negras, por favor... Ah, y una pregunta: ¿no ha visto a mi gato? Blanco, con un ojo de cada color.",
		opciones = {
			{
				id = "verdad",
				texto = "\"Sí, lo vi correr hacia el bosque\"",
				respuesta = "La señora asiente despacio. \"Hacia el bosque... claro. Gracias por su honestidad, joven. Eso se recompensa.\"",
				banderas = { dijiste_verdad_elvira = true },
			},
			{
				id = "mentir",
				texto = "\"No, no he visto ningún gato\"",
				respuesta = "La señora te mira fijamente tres segundos de más. \"Qué curioso. Él sí lo vio a usted.\" Paga y se va.",
				banderas = { mentiste_elvira = true },
			},
		},
	},

	-- ═══════════════ CLIENTE 3: paranormal ═══════════════
	{
		id = "hombre_palido",
		nombre = "Hombre pálido",
		hora = "12:00 AM",
		dialogo = "Dame... lo de siempre. (No parpadea. Nunca lo has visto en tu vida, pero en la trastienda hay un frasco sin etiqueta que nadie te explicó.)",
		opciones = {
			{
				id = "dar_frasco",
				texto = "Darle el frasco de la trastienda",
				respuesta = "Toma el frasco sin mirarlo. \"Buen empleado. Los otros siempre preguntaban.\" Deja un billete que no reconoces.",
				banderas = { entregaste_frasco = true },
			},
			{
				id = "no_hay",
				texto = "\"No sé de qué me habla\"",
				respuesta = "Ladea la cabeza como un pájaro. \"Nuevo... ya veo. Volveré cuando sepas.\" Sale sin abrir la puerta.",
				banderas = { rechazaste_palido = true },
			},
		},
	},

	-- ═══════════════ CLIENTE 4: condicional ═══════════════
	-- Este cliente SOLO aparece si le fiaste la sopa al chico (cliente 1).
	-- Es el ejemplo de cómo una decisión temprana cambia la noche.
	{
		id = "doble_chico",
		nombre = "¿Chico con sudadera?",
		hora = "1:30 AM",
		dialogo = "Quiero esta sopa instantánea pero me faltan 8 pesos. ¿Me la fías? (Es idéntico al de hace tres horas. MISMA ropa. MISMAS palabras. Pero él ya vino... ¿no?)",
		condicion = function(banderas)
			return banderas.fiaste_sopa == true
		end,
		opciones = {
			{
				id = "fiar_doble",
				texto = "Fiarle otra vez, sin preguntar",
				respuesta = "Toma la sopa. Al salir, se detiene y dice sin voltear: \"Gracias por no preguntar.\" La puerta no suena al cerrarse.",
				banderas = { fiaste_al_doble = true },
			},
			{
				id = "confrontar",
				texto = "\"Tú ya viniste hace rato...\"",
				respuesta = "Se queda inmóvil. \"...No. Ese no era yo.\" Deja la sopa y camina de espaldas hasta la puerta, mirándote todo el tiempo.",
				banderas = { confrontaste_al_doble = true },
			},
		},
	},

	-- ═══════════════ CLIENTE 5: la cámara ═══════════════
	{
		id = "encapuchado",
		nombre = "Encapuchado",
		hora = "2:45 AM",
		dialogo = "(Las luces parpadean. Alguien entra con la capucha puesta y señala la cámara de seguridad.) Apágala cinco minutos. Nadie tiene que saber que estuve aquí. Te conviene.",
		opciones = {
			{
				id = "apagar",
				texto = "Apagar la cámara",
				respuesta = "Apagas la cámara. El encapuchado camina al fondo de la tienda... y cuando la enciendes de nuevo, ya no hay nadie. No escuchaste la puerta.",
				banderas = { apagaste_camara = true },
			},
			{
				id = "negarse",
				texto = "Negarte",
				respuesta = "\"Mala decisión, empleado del mes.\" Se va. La cámara ahora te apunta A TI, aunque nadie la movió.",
				banderas = { protegiste_camara = true },
			},
		},
	},

	-- ═══════════════ CLIENTE 6: el gato ═══════════════
	{
		id = "gato",
		nombre = "Un gato blanco",
		hora = "4:00 AM",
		dialogo = "(Un gato blanco con un ojo de cada color entra y salta al mostrador. Te mira como si esperara algo. Es, sin duda, el gato de la señora Elvira.)",
		opciones = {
			{
				id = "leche",
				texto = "Darle un plato de leche",
				respuesta = "El gato bebe con calma. Antes de irse, te mira y juras escuchar una voz: \"Ella lo sabrá.\"",
				banderas = { alimentaste_gato = true },
			},
			{
				id = "sacarlo",
				texto = "Sacarlo de la tienda",
				respuesta = "Lo cargas hacia la puerta. Pesa demasiado para ser un gato. Al soltarlo, ya no está. Solo quedan huellas... que entran, no salen.",
				banderas = { sacaste_gato = true },
			},
		},
	},

	-- ═══════════════ CLIENTE 7: el reemplazo ═══════════════
	{
		id = "reemplazo",
		nombre = "Tu reemplazo",
		hora = "5:30 AM",
		dialogo = "Llegué temprano al turno de la mañana. Ya vete a descansar, yo cierro caja. (Levanta la cara. Es idéntico a ti. TU cara. TU uniforme. TU gafete.)",
		opciones = {
			{
				id = "entregar",
				texto = "Entregarle el turno e irte",
				respuesta = "Le das las llaves. Al salir, te ves a ti mismo detrás del mostrador, saludándote con tu propia mano...",
				banderas = { entregaste_turno = true },
			},
			{
				id = "quedarse",
				texto = "\"Este es MI turno. Vete.\"",
				respuesta = "Sonríe con tu sonrisa. \"Correcto. Esa era la prueba.\" Se deshace en el aire como vapor. El reloj marca casi las 6.",
				banderas = { defendiste_turno = true },
			},
		},
	},
}

return ClientesData
